--[[
LuCI - Network model

Copyright 2009-2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]--

local type, next, pairs, ipairs, loadfile, table
	= type, next, pairs, ipairs, loadfile, table

local tonumber, tostring, math = tonumber, tostring, math

local require = require

local bus = require "ubus"
local nxo = require "nixio"
local nfs = require "nixio.fs"
local ipc = require "luci.ip"
local sys = require "luci.sys"
local utl = require "luci.util"
local dsp = require "luci.dispatcher"
local uci = require "luci.model.uci"
local lng = require "luci.i18n"

module "luci.model.network"


IFACE_PATTERNS_VIRTUAL  = { }
IFACE_PATTERNS_IGNORE   = { "^wmaster%d", "^wifi%d", "^hwsim%d", "^imq%d", "^ifb%d", "^mon%.wlan%d", "^sit%d", "^gre%d", "^lo$","sar$","swc$","bcmsw$","dsl%d","^atm%d$","^ptm%d$","^radiotap%d$","^vap%d$"}
IFACE_PATTERNS_WIRELESS = { "^wlan%d", "^wl%d", "^ath%d", "^%w+%.network%d" }


protocol = utl.class()

local _protocols = { }

local _interfaces, _bridge, _switch, _tunnel
local _ubus, _ubusnetcache, _ubusdevcache
local _uci_real, _uci_state

function _filter(c, s, o, r)
	local val = _uci_real:get(c, s, o)
	if val then
		local l = { }
		if type(val) == "string" then
			for val in val:gmatch("%S+") do
				if val ~= r then
					l[#l+1] = val
				end
			end
			if #l > 0 then
				_uci_real:set(c, s, o, table.concat(l, " "))
			else
				_uci_real:delete(c, s, o)
			end
		elseif type(val) == "table" then
			for _, val in ipairs(val) do
				if val ~= r then
					l[#l+1] = val
				end
			end
			if #l > 0 then
				_uci_real:set(c, s, o, l)
			else
				_uci_real:delete(c, s, o)
			end
		end
	end
end

function _append(c, s, o, a)
	local val = _uci_real:get(c, s, o) or ""
	if type(val) == "string" then
		local l = { }
		for val in val:gmatch("%S+") do
			if val ~= a then
				l[#l+1] = val
			end
		end
		l[#l+1] = a
		_uci_real:set(c, s, o, table.concat(l, " "))
	elseif type(val) == "table" then
		local l = { }
		for _, val in ipairs(val) do
			if val ~= a then
				l[#l+1] = val
			end
		end
		l[#l+1] = a
		_uci_real:set(c, s, o, l)
	end
end

function _stror(s1, s2)
	if not s1 or #s1 == 0 then
		return s2 and #s2 > 0 and s2
	else
		return s1
	end
end

function _get(c, s, o)
	return _uci_real:get(c, s, o)
end

function _set(c, s, o, v)
	if v ~= nil then
		if type(v) == "boolean" then v = v and "1" or "0" end
		return _uci_real:set(c, s, o, v)
	else
		return _uci_real:delete(c, s, o)
	end
end

function _wifi_iface(x)
	local _, p
	for _, p in ipairs(IFACE_PATTERNS_WIRELESS) do
		if x:match(p) then
			return true
		end
	end
	return false
end

function _wifi_lookup(ifn)
	-- got a radio#.network# pseudo iface, locate the corresponding section
	local radio, ifnidx = ifn:match("^(%w+)%.network(%d+)$")
	if radio and ifnidx then
		local sid = nil
		local num = 0

		ifnidx = tonumber(ifnidx)
		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				if s.device == radio then
					num = num + 1
					if num == ifnidx then
						sid = s['.name']
						return false
					end
				end
			end)

		return sid

	-- looks like wifi, try to locate the section via state vars
	elseif _wifi_iface(ifn) then
		local sid = nil

		_uci_state:foreach("wireless", "wifi-iface",
			function(s)
				if s.ifname == ifn then
					sid = s['.name']
					return false
				end
			end)

		return sid
	end
end

function _iface_virtual(x)
	local _, p
	for _, p in ipairs(IFACE_PATTERNS_VIRTUAL) do
		if x:match(p) then
			return true
		end
	end
	return false
end

function _iface_ignore(x)
	local _, p
	for _, p in ipairs(IFACE_PATTERNS_IGNORE) do
		if x:match(p) then
			return true
		end
	end
	return _iface_virtual(x)
end


function init(cursor)
	_uci_real  = cursor or _uci_real or uci.cursor()
	_uci_state = _uci_real:substate()

	_interfaces = { }
	_bridge     = { }
	_switch     = { }
	_tunnel     = { }

	_ubus         = bus.connect()
	_ubusnetcache = { }
	_ubusdevcache = { }

	-- read interface information
	local n, i
	for n, i in ipairs(nxo.getifaddrs()) do
		local name = i.name:match("[^:]+")
		local prnt = name:match("^([^%.]+)%.")

		if _iface_virtual(name) then
			_tunnel[name] = true
		end

		if _tunnel[name] or not _iface_ignore(name) then
			_interfaces[name] = _interfaces[name] or {
				idx      = i.ifindex or n,
				name     = name,
				rawname  = i.name,
				flags    = { },
				ipaddrs  = { },
				ip6addrs = { }
			}

			if prnt then
				_switch[name] = true
				_switch[prnt] = true
			end

			if i.family == "packet" then
				_interfaces[name].flags   = i.flags
				_interfaces[name].stats   = i.data
				_interfaces[name].macaddr = i.addr
			elseif i.family == "inet" then
				_interfaces[name].ipaddrs[#_interfaces[name].ipaddrs+1] = ipc.IPv4(i.addr, i.netmask)
			elseif i.family == "inet6" then
				_interfaces[name].ip6addrs[#_interfaces[name].ip6addrs+1] = ipc.IPv6(i.addr, i.netmask)
			end
		end
	end

	-- read bridge informaton
	local b, l
	for l in utl.execi("brctl show") do
		if not l:match("STP") then
			local r = utl.split(l, "%s+", nil, true)
			if #r == 4 then
				b = {
					name    = r[1],
					id      = r[2],
					stp     = r[3] == "yes",
					ifnames = { _interfaces[r[4]] }
				}
				if b.ifnames[1] then
					b.ifnames[1].bridge = b
				end
				_bridge[r[1]] = b
			elseif b then
				b.ifnames[#b.ifnames+1] = _interfaces[r[2]]
				b.ifnames[#b.ifnames].bridge = b
			end
		end
	end

	return _M
end

function save(self, ...)
	_uci_real:save(...)
	_uci_real:load(...)
end

function commit(self, ...)
	_uci_real:commit(...)
	_uci_real:load(...)
end

function ifnameof(self, x)
	if utl.instanceof(x, interface) then
		return x:name()
	elseif utl.instanceof(x, protocol) then
		return x:ifname()
	elseif type(x) == "string" then
		return x:match("^[^:]+")
	end
end

function get_protocol(self, protoname, netname)
	local v = _protocols[protoname]
	if v then
		return v(netname or "__dummy__")
	end
end

function get_protocols(self)
	local p = { }
	local _, v
	for _, v in ipairs(_protocols) do
		p[#p+1] = v("__dummy__")
	end
	return p
end

function register_protocol(self, protoname)
	local proto = utl.class(protocol)

	function proto.__init__(self, name)
		self.sid = name
	end

	function proto.proto(self)
		return protoname
	end

	_protocols[#_protocols+1] = proto
	_protocols[protoname]     = proto

	return proto
end

function register_pattern_virtual(self, pat)
	IFACE_PATTERNS_VIRTUAL[#IFACE_PATTERNS_VIRTUAL+1] = pat
end


function has_ipv6(self)
	return nfs.access("/proc/net/ipv6_route")
end

function add_network(self, n, options)
	local oldnet = self:get_network(n)
	if n and #n > 0 and n:match("^[a-zA-Z0-9_]+$") and not oldnet then
		if _uci_real:section("network", "interface", n, options) then
			return network(n)
		end
	elseif oldnet and oldnet:is_empty() then
		if options then
			local k, v
			for k, v in pairs(options) do
				oldnet:set(k, v)
			end
		end
		return oldnet
	end
end

function get_network(self, n)
	if n and _uci_real:get("network", n) == "interface" then
		return network(n)
	end
end

function get_networks(self)
	local nets = { }
	local nls = { }

	_uci_real:foreach("network", "interface",
		function(s)
			nls[s['.name']] = network(s['.name'])
		end)

	local n
	for n in utl.kspairs(nls) do
		nets[#nets+1] = nls[n]
	end

	return nets
end

function is_local_network(self, n)
	if n and _uci_real:get("network", n, "is_lan") == "1" then
		return true
	end
	return false
end

function del_network(self, n)
	local d = _uci_real:delete("dhcp", n)
	local r = _uci_real:delete("network", n)
	if r then
		_uci_real:delete_all("network", "alias",
			function(s) return (s.interface == n) end)

		_uci_real:delete_all("network", "route",
			function(s) return (s.interface == n) end)

		_uci_real:delete_all("network", "route6",
			function(s) return (s.interface == n) end)

		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				local net
				local rest = { }
				for net in utl.imatch(s.network) do
					if net ~= n then
						rest[#rest+1] = net
					end
				end
				if #rest > 0 then
					_uci_real:set("wireless", s['.name'], "network",
					              table.concat(rest, " "))
				else
					_uci_real:delete("wireless", s['.name'], "network")
				end
			end)
	end
	return r, d
end

function rename_network(self, old, new)
	local r
	if new and #new > 0 and new:match("^[a-zA-Z0-9_]+$") and not self:get_network(new) then
		r = _uci_real:section("network", "interface", new, _uci_real:get_all("network", old))

		if r then
			_uci_real:foreach("network", "alias",
				function(s)
					if s.interface == old then
						_uci_real:set("network", s['.name'], "interface", new)
					end
				end)

			_uci_real:foreach("network", "route",
				function(s)
					if s.interface == old then
						_uci_real:set("network", s['.name'], "interface", new)
					end
				end)

			_uci_real:foreach("network", "route6",
				function(s)
					if s.interface == old then
						_uci_real:set("network", s['.name'], "interface", new)
					end
				end)

			_uci_real:foreach("wireless", "wifi-iface",
				function(s)
					local net
					local list = { }
					for net in utl.imatch(s.network) do
						if net == old then
							list[#list+1] = new
						else
							list[#list+1] = net
						end
					end
					if #list > 0 then
						_uci_real:set("wireless", s['.name'], "network",
						              table.concat(list, " "))
					end
				end)

			_uci_real:delete("network", old)
		end
	end
	return r or false
end

function get_interface(self, i)
	if _interfaces[i] or _wifi_iface(i) then
		return interface(i)
	else
		local ifc
		local num = { }
		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				if s.device then
					num[s.device] = num[s.device] and num[s.device] + 1 or 1
					if s['.name'] == i then
						ifc = interface(
							"%s.network%d" %{s.device, num[s.device] })
						return false
					end
				end
			end)
		return ifc
	end
end

function get_interfaces(self)
	local iface
	local ifaces = { }
	local seen = { }
	local nfs = { }
	local baseof = { }
	local ethwan= _uci_real:get("layer2_interface_ethernet", "Wan", "baseifname")

	-- find normal interfaces
	_uci_real:foreach("network", "interface",
		function(s)
			for iface in utl.imatch(s.ifname) do
				if not _iface_ignore(iface) and not _wifi_iface(iface) then
					seen[iface] = true
					nfs[iface] = interface(iface)
				end
			end
		end)
	_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_vlan", "vlan_interface",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	for iface in utl.kspairs(_interfaces) do
		if not (seen[iface] or _iface_ignore(iface) or _wifi_iface(iface) or ethwan==iface) then
			nfs[iface] = interface(iface)
		end
	end

	-- find vlan interfaces
	_uci_real:foreach("network", "switch_vlan",
		function(s)
			if not s.device then
				return
			end

			local base = baseof[s.device]
			if not base then
				if not s.device:match("^eth%d") then
					local l
					for l in utl.execi("swconfig dev %q help 2>/dev/null" % s.device) do
						if not base then
							base = l:match("^%w+: (%w+)")
						end
					end
					if not base or not base:match("^eth%d") then
						base = "eth0"
					end
				else
					base = s.device
				end
				baseof[s.device] = base
			end

			local vid = tonumber(s.vid or s.vlan)
			if vid ~= nil and vid >= 0 and vid <= 4095 then
				local iface = "%s.%d" %{ base, vid }
				if not seen[iface] then
					seen[iface] = true
					nfs[iface] = interface(iface)
				end
			end
		end)

	for iface in utl.kspairs(nfs) do
		ifaces[#ifaces+1] = nfs[iface]
	end

	-- find wifi interfaces
	local num = { }
	local wfs = { }
	_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.device then
				num[s.device] = num[s.device] and num[s.device] + 1 or 1
				local i = "%s.network%d" %{ s.device, num[s.device] }
				wfs[i] = interface(i)
			end
		end)

	for iface in utl.kspairs(wfs) do
		ifaces[#ifaces+1] = wfs[iface]
	end

	return ifaces
end

function ignore_interface(self, x)
	return _iface_ignore(x)
end

function get_wifidev(self, dev)
	if _uci_real:get("wireless", dev) == "wifi-device" then
		return wifidev(dev)
	end
end

function get_wifidevs(self)
	local devs = { }
	local wfd  = { }

	_uci_real:foreach("wireless", "wifi-device",
		function(s) wfd[#wfd+1] = s['.name'] end)

	local dev
	for _, dev in utl.vspairs(wfd) do
		devs[#devs+1] = wifidev(dev)
	end

	return devs
end

function get_wifinet(self, net)
	local wnet = _wifi_lookup(net)
	if wnet then
		return wifinet(wnet)
	end
end

function add_wifinet(self, net, options)
	if type(options) == "table" and options.device and
		_uci_real:get("wireless", options.device) == "wifi-device"
	then
		local wnet = _uci_real:section("wireless", "wifi-iface", nil, options)
		return wifinet(wnet)
	end
end

function del_wifinet(self, net)
	local wnet = _wifi_lookup(net)
	if wnet then
		_uci_real:delete("wireless", wnet)
		return true
	end
	return false
end

function get_status_by_route(self, addr, mask)
	local _, object
	for _, object in ipairs(_ubus:objects()) do
		local net = object:match("^network%.interface%.(.+)")
		if net then
			local s = _ubus:call(object, "status", {})
			if s and s.route then
				local rt
				for _, rt in ipairs(s.route) do
					if not rt.table and rt.target == addr and rt.mask == mask then
						return net, s
					end
				end
			end
		end
	end
end

function get_status_by_address(self, addr)
	local _, object
	for _, object in ipairs(_ubus:objects()) do
		local net = object:match("^network%.interface%.(.+)")
		if net then
			local s = _ubus:call(object, "status", {})
			if s and s['ipv4-address'] then
				local a
				for _, a in ipairs(s['ipv4-address']) do
					if a.address == addr then
						return net, s
					end
				end
			end
			if s and s['ipv6-address'] then
				local a
				for _, a in ipairs(s['ipv6-address']) do
					if a.address == addr then
						return net, s
					end
				end
			end
		end
	end
end

function get_wannet(self)
	local net = self:get_status_by_route("0.0.0.0", 0)
	return net and network(net)
end

function get_wandev(self)
	local _, stat = self:get_status_by_route("0.0.0.0", 0)
	return stat and interface(stat.l3_device or stat.device)
end

function get_wan6net(self)
	local net = self:get_status_by_route("::", 0)
	return net and network(net)
end

function get_wan6dev(self)
	local _, stat = self:get_status_by_route("::", 0)
	return stat and interface(stat.l3_device or stat.device)
end


function network(name, proto)
	if name then
		local p = proto or _uci_real:get("network", name, "proto")
		local c = p and _protocols[p] or protocol
		return c(name)
	end
end

function get_layer2interfacesbase(self)
	local iface
	local ifaces = { }
	local seen = { }
	local nfs = { }
	local baseof = { }

	
	_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
		function(s)
			for iface in utl.imatch(s.baseifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
		function(s)
			for iface in utl.imatch(s.baseifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
		function(s)
			for iface in utl.imatch(s.baseifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	
	for iface in utl.kspairs(nfs) do
		ifaces[#ifaces+1] = nfs[iface]
	end
	return ifaces
end
function get_layer2interfaces(self)
	local iface
	local ifaces = { }
	local seen = { }
	local nfs = { }
	local baseof = { }

	
	_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	_uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
		function(s)
			for iface in utl.imatch(s.ifname) do
				
					seen[iface] = true
					nfs[iface] = interface(iface)	
					
			end
		end)
	
	for iface in utl.kspairs(nfs) do
		ifaces[#ifaces+1] = nfs[iface]
	end
	return ifaces
end
-- get interfaces that have been created
function get_upinterfaces(self)
	local iface
	local ifaces = { }
	local seen = { }
	local nfs = { }
	local baseof = { }

	for iface in utl.kspairs(_interfaces) do
		if not (seen[iface] or _iface_ignore(iface) or _wifi_iface(iface) or ethwan==iface) then
			nfs[iface] = interface(iface)
		end
	end
	
	
	for iface in utl.kspairs(nfs) do
		ifaces[#ifaces+1] = nfs[iface]
	end
	return ifaces
end

function protocol.__init__(self, name)
	self.sid = name
end

function protocol._get(self, opt)
	local v = _uci_real:get("network", self.sid, opt)
	if type(v) == "table" then
		return table.concat(v, " ")
	end
	return v or ""
end

function protocol._ubus(self, field)
	if not _ubusnetcache[self.sid] then
		_ubusnetcache[self.sid] = _ubus:call("network.interface.%s" % self.sid,
		                                     "status", { })
	end
	if _ubusnetcache[self.sid] and field then
		return _ubusnetcache[self.sid][field]
	end
	return _ubusnetcache[self.sid]
end

function protocol.get(self, opt)
	return _get("network", self.sid, opt)
end

function protocol.set(self, opt, val)
	return _set("network", self.sid, opt, val)
end

function protocol.ifname(self)
	local ifname
	if self:is_floating() then
		ifname = self:_ubus("l3_device")
	else
		ifname = self:_ubus("device")
	end
	if not ifname then
		local num = { }
		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				if s.device then
					num[s.device] = num[s.device]
						and num[s.device] + 1 or 1

					local net
					for net in utl.imatch(s.network) do
						if net == self.sid then
							ifname = "%s.network%d" %{ s.device, num[s.device] }
							return false
						end
					end
				end
			end)
	end
	return ifname
end

function protocol.proto(self)
	return "none"
end

function protocol.get_i18n(self)
	local p = self:proto()
	if p == "none" then
		return lng.translate("Unmanaged")
	elseif p == "static" then
		return lng.translate("Static address")
	elseif p == "dhcp" then
		return lng.translate("DHCP client")
	else
		return lng.translate("Unknown")
	end
end

function protocol.type(self)
	return self:_get("type")
end

function protocol.name(self)
	return self.sid
end

function protocol.uptime(self)
	return self:_ubus("uptime") or 0
end

function protocol.expires(self)
	local a = tonumber(_uci_state:get("network", self.sid, "lease_acquired"))
	local l = tonumber(_uci_state:get("network", self.sid, "lease_lifetime"))
	if a and l then
		l = l - (nxo.sysinfo().uptime - a)
		return l > 0 and l or 0
	end
	return -1
end

function protocol.metric(self)
	return tonumber(_uci_state:get("network", self.sid, "metric")) or 0
end

function protocol.ipaddr(self)
	local addrs = self:_ubus("ipv4-address")
	return addrs and #addrs > 0 and addrs[1].address
end

function protocol.netmask(self)
	local addrs = self:_ubus("ipv4-address")
	return addrs and #addrs > 0 and
		ipc.IPv4("0.0.0.0/%d" % addrs[1].mask):mask():string()
end

function protocol.gwaddr(self)
	local _, route
	for _, route in ipairs(self:_ubus("route") or { }) do
		if route.target == "0.0.0.0" and route.mask == 0 then
			return route.nexthop
		end
	end
end

function protocol.dnsaddrs(self)
	local dns = { }
	local _, addr
	for _, addr in ipairs(self:_ubus("dns-server") or { }) do
		if not addr:match(":") then
			dns[#dns+1] = addr
		end
	end
	return dns
end

function protocol.ip6addr(self)
	local addrs = self:_ubus("ipv6-address")
	if addrs and #addrs > 0 then
		return "%s/%d" %{ addrs[1].address, addrs[1].mask }
	else
		addrs = self:_ubus("ipv6-prefix-assignment")
		if addrs and #addrs > 0 then
			return "%s/%d" %{ addrs[1].address, addrs[1].mask }
		end
	end
end

function protocol.gw6addr(self)
	local _, route
	for _, route in ipairs(self:_ubus("route") or { }) do
		if route.target == "::" and route.mask == 0 then
			return ipc.IPv6(route.nexthop):string()
		end
	end
end

function protocol.dns6addrs(self)
	local dns = { }
	local _, addr
	for _, addr in ipairs(self:_ubus("dns-server") or { }) do
		if addr:match(":") then
			dns[#dns+1] = addr
		end
	end
	return dns
end

function protocol.is_lan(self)
	return (self:_get("is_lan") == "1")
end

function protocol.is_bridge(self)
	return (not self:is_virtual() and self:type() == "bridge")
end

function protocol.is_anywan(self)
	return (not self:is_virtual() and self:type() == "anywan")
end

function protocol.opkg_package(self)
	return nil
end

function protocol.is_installed(self)
	return true
end

function protocol.is_virtual(self)
	return false
end

function protocol.is_floating(self)
	return false
end

function protocol.is_semivirtual(self)
	return false
end

function protocol.is_semifloating(self)
	return false
end

function protocol.is_empty(self)
	if self:is_floating() then
		return false
	else
		local rv = true

		if (self:_get("ifname") or ""):match("%S+") then
			rv = false
		end

		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				local n
				for n in utl.imatch(s.network) do
					if n == self.sid then
						rv = false
						return false
					end
				end
			end)

		return rv
	end
end

function protocol.add_interface(self, ifname)
	ifname = _M:ifnameof(ifname)
	if ifname and not self:is_floating() then
		-- if its a wifi interface, change its network option
		local wif = _wifi_lookup(ifname)
		if wif then
			_append("wireless", wif, "network", self.sid)

		-- add iface to our iface list
		else
			_append("network", self.sid, "ifname", ifname)
		end
	end
end

function protocol.del_interface(self, ifname)
	ifname = _M:ifnameof(ifname)
	if ifname and not self:is_floating() then
		-- if its a wireless interface, clear its network option
		local wif = _wifi_lookup(ifname)
		if wif then _filter("wireless", wif, "network", self.sid) end

		-- remove the interface
		_filter("network", self.sid, "ifname", ifname)
	end
end

function protocol.get_interface(self)
	if self:is_virtual() then
		_tunnel[self:proto() .. "-" .. self.sid] = true
		return interface(self:proto() .. "-" .. self.sid, self)
	elseif self:is_bridge() then
		_bridge["br-" .. self.sid] = true
		return interface("br-" .. self.sid, self)
	elseif self:is_anywan() then
		local ifn = nil
		local frstifn = ""
		for ifn in utl.imatch(_uci_real:get("network", self.sid, "ifname")) do
			ifn = ifn:match("^[^:/]+")
			if ifn then
				frstifn = ifn
				break
			end
		end
		return interface(self:_ubus("device") or frstifn)
	else
		local ifn = nil
		local num = { }
		for ifn in utl.imatch(_uci_real:get("network", self.sid, "ifname")) do
			ifn = ifn:match("^[^:/]+")
			return ifn and interface(ifn, self)
		end
		ifn = nil
		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				if s.device then
					num[s.device] = num[s.device] and num[s.device] + 1 or 1

					local net
					for net in utl.imatch(s.network) do
						if net == self.sid then
							ifn = "%s.network%d" %{ s.device, num[s.device] }
							return false
						end
					end
				end
			end)
		return ifn and interface(ifn, self)
	end
end

function protocol.get_interfaces(self)
	if self:is_bridge() or self:is_anywan() or (not self:is_floating()) then
		local ifaces = { }

		local ifn
		local nfs = { }
		for ifn in utl.imatch(self:get("ifname")) do
			if not ifn:match("^wl%d") then
				ifn = ifn:match("^[^:/]+")
				nfs[ifn] = interface(ifn, self)
			end
		end

		for ifn in utl.kspairs(nfs) do
			ifaces[#ifaces+1] = nfs[ifn]
		end

		local num = { }
		local wfs = { }
		_uci_real:foreach("wireless", "wifi-iface",
			function(s)
				if s.device then
					num[s.device] = num[s.device] and num[s.device] + 1 or 1

					local net
					for net in utl.imatch(s.network) do
						if net == self.sid then
							ifn = "%s.network%d" %{ s.device, num[s.device] }
							wfs[ifn] = interface(ifn, self)
						end
					end
				end
			end)

		for ifn in utl.kspairs(wfs) do
			ifaces[#ifaces+1] = wfs[ifn]
		end

		return ifaces
	end
end

function protocol.contains_interface(self, ifname)
	ifname = _M:ifnameof(ifname)
	if not ifname then
		return false
	elseif self:is_virtual() and self:proto() .. "-" .. self.sid == ifname then
		return true
	elseif self:is_bridge() and "br-" .. self.sid == ifname then
		return true
	elseif self:is_anywan() and self:_ubus("device") == ifname then
		return true
	else
		local ifn
		for ifn in utl.imatch(self:get("ifname")) do
			ifn = ifn:match("[^:]+")
			if ifn == ifname then
				return true
			end
		end

		local wif = _wifi_lookup(ifname)
		if wif then
			local n
			for n in utl.imatch(_uci_real:get("wireless", wif, "network")) do
				if n == self.sid then
					return true
				end
			end
		end
	end

	return false
end

function protocol.adminlink(self)
	return dsp.build_url("admin", "network", "network", self.sid)
end


interface = utl.class()

function interface.__init__(self, ifname, network)
	local wif = _wifi_lookup(ifname)
	if wif then
		self.wif    = wifinet(wif)
		self.ifname = _uci_state:get("wireless", wif, "ifname")
	end

	self.ifname  = self.ifname or ifname
	self.dev     = _interfaces[self.ifname]
	self.network = network
end

function interface._ubus(self, field)
	if not _ubusdevcache[self.ifname] then
		_ubusdevcache[self.ifname] = _ubus:call("network.device", "status",
		                                        { name = self.ifname })
	end
	if _ubusdevcache[self.ifname] and field then
		return _ubusdevcache[self.ifname][field]
	end
	return _ubusdevcache[self.ifname]
end

function interface.name(self)
	return self.wif and self.wif:ifname() or self.ifname
end

function interface.mac(self)
	return (self:_ubus("macaddr") or "00:00:00:00:00:00"):upper()
end

function interface.ipaddrs(self)
	return self.dev and self.dev.ipaddrs or { }
end

function interface.ip6addrs(self)
	return self.dev and self.dev.ip6addrs or { }
end

function interface.type(self)
	if self.wif or _wifi_iface(self.ifname) then
		return "wifi"
	elseif _bridge[self.ifname] then
		return "bridge"
	elseif _tunnel[self.ifname] then
		return "tunnel"
	elseif self.ifname:match("^eth%d.1$") then
		return "ethernetwan"
	elseif self.ifname:match("^wwan%d$") then
		return "wwan"
	elseif self.ifname:match("^atm%d.1$")  then
		return "adsl"
	elseif self.ifname:match("^ptm%d.1$") then
		return "vdsl2"
	elseif self.ifname:match("%.%d*") then
		return "vlan"
	elseif _switch[self.ifname] then
		return "switch"
	else
		return "ethernet"
	end
end

function interface.portname(self)
	return sys.exec(". /lib/network/config.sh && interfacename %s" %self.ifname)
end

function interface.layer2name(self)
	local seen = self.ifname
	local names="messedup"
	if self.ifname:match("atm%d")  then
	name=_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
		function(s)
			if seen:match(s.baseifname) then
				names=s.name		  
				
			end
		end)  
		return names
	end
	if self.ifname:match("ptm%d")  then
	name=_uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
		function(s)
			if seen:match(s.baseifname) then
				names=s.name		  
				
			end
		end)  
		return names
	end
	if self.ifname:match("eth%d")  then
	name=_uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
		function(s)
			if seen:match(s.baseifname) then
				names=s.name		  
				
			end
		end)  
		return names
	end
end

function interface.shortname(self)
	if self.wif then
		return "%s %q" %{
			self.wif:active_mode(),
			self.wif:active_ssid() or self.wif:active_bssid()
		}
	else
		return self.ifname
	end
end

function interface.get_i18n(self)
	if self.wif then
		return "%s: %s %q" %{
			lng.translate("Wireless Network"),
			self.wif:active_mode(),
			self.wif:active_ssid() or self.wif:active_bssid()
		}
	elseif self:name():match("^eth%d$") then
		return "%s: %s" %{ self:get_type_i18n(), self:portname().."->"..self:name() }
	elseif self:type()=="vlan" or  self:type()=="adsl" or self:type()=="vdsl2" or self:type()=="ethernetwan"    then
		return "%s: %s" %{ self:get_type_i18n(), self:get_linklayername().."->"..self:name() }
	else
		return "%s: %q" %{ self:get_type_i18n(), self:name() }
	end
end

function interface.get_type_i18n(self)
	local x = self:type()
	if x == "wifi" then
		return lng.translate("Wireless Adapter")
	elseif x == "bridge" then
		return lng.translate("Bridge")
	elseif x == "switch" then
		return lng.translate("Ethernet Switch")
	elseif x == "vlan" then
		return lng.translate("VLAN Interface")
	elseif x == "tunnel" then
		return lng.translate("Tunnel Interface")
	elseif x == "vdsl2" then
		return lng.translate("VDSL")
	elseif x == "adsl" then
		return lng.translate("ADSL")	
	elseif x == "ethernetwan" then
		return lng.translate("Ethernet WAN")
	elseif x == "wwan" then
		return lng.translate("Wireless WAN")
	else 
		return lng.translate("Ethernet Adapter")
	end
end

function interface.adminlink(self)
	if self.wif then
		return self.wif:adminlink()
	end
	layer2type=self:type()
	if layer2type == "adsl" then
		return dsp.build_url("admin", "network", "layer2_interface", "layer2_interface_adsl")
	elseif  layer2type== "vdsl2" then
		return dsp.build_url("admin", "network", "layer2_interface", "layer2_interface_vdsl")
	elseif layer2type == "vlan" then
		return dsp.build_url("admin", "network", "layer2_interface", "layer2_interface_vlan")
	elseif layer2type == "ethernetwan" then
		return dsp.build_url("admin", "network", "layer2_interface", "layer2_interface_ethernet")
	
	end
end

function interface.ports(self)
	local members = self:_ubus("bridge-members")
	if members then
		local _, iface
		local ifaces = { }
		for _, iface in ipairs(members) do
			ifaces[#ifaces+1] = interface(iface)
		end
	end
end

function interface.bridge_id(self)
	if self.br then
		return self.br.id
	else
		return nil
	end
end

function interface.bridge_stp(self)
	if self.br then
		return self.br.stp
	else
		return false
	end
end

function interface.is_up(self)
	if self.wif then
		return self.wif:is_up()
	else
		return self:_ubus("up") or false
	end
end

function interface.is_bridge(self)
	return (self:type() == "bridge")
end

function interface.is_bridgeport(self)
	return self.dev and self.dev.bridge and true or false
end

function interface.tx_bytes(self)
	local stat = self:_ubus("statistics")
	return stat and stat.tx_bytes or 0
end

function interface.rx_bytes(self)
	local stat = self:_ubus("statistics")
	return stat and stat.rx_bytes or 0
end

function interface.tx_packets(self)
	local stat = self:_ubus("statistics")
	return stat and stat.tx_packets or 0
end

function interface.rx_packets(self)
	local stat = self:_ubus("statistics")
	return stat and stat.rx_packets or 0
end

function interface.get_network(self)
	return self:get_networks()[1]
end

function interface.get_networks(self)
	if not self.networks then
		local nets = { }
		local _, net
		for _, net in ipairs(_M:get_networks()) do
			if net:contains_interface(self.ifname) or
			   net:ifname() == self.ifname
			then
				nets[#nets+1] = net
			end
		end
		table.sort(nets, function(a, b) return a.sid < b.sid end)
		self.networks = nets
		return nets
	else
		return self.networks
	end
end

function interface.get_linklayername(self)
	local nameofdevice="Ethernet"
	local hej=self:type()
	if self:type()=="vlan" then
	_uci_real:foreach("layer2_interface_vlan", "vlan_interface",
		function(s)
				if self.ifname==s.ifname then
				  nameofdevice=s.name  
				end
		end)
	elseif hej=="ethernetwan" then    
	  _uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
		function(s)
			  if self.ifname==s.ifname then
				  nameofdevice=s.name	  
				end
		end)	
	elseif self:type()=="adsl" then	    
	_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
		function(s)
			  if self.ifname==s.ifname then
				  nameofdevice=s.name
				end
		end)
			 
	elseif self:type()=="vdsl2" then    
	  _uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
		function(s)
			  if self.ifname==s.ifname then
				  nameofdevice=s.name	  
				end
		end)
	end
	
	return nameofdevice 
end
function interface.get_wifinet(self)
	return self.wif
end


wifidev = utl.class()

function wifidev.__init__(self, dev)
	self.sid    = dev
	self.iwinfo = dev and sys.wifi.getiwinfo(dev) or { }
end

function wifidev.get(self, opt)
	return _get("wireless", self.sid, opt)
end

function wifidev.set(self, opt, val)
	return _set("wireless", self.sid, opt, val)
end

function wifidev.name(self)
	return self.sid
end

function wifidev.version(self)
        local version = "0"
	version=sys.exec("wlctl -i %s revinfo | awk 'FNR == 2 {print}' | cut -d\"x\" -f2 " %self:name())
	return version:gsub("\n$", "")  
end

function wifidev.is_sta_capable(self)
	return sys.exec("wlctl -i %q cap" %self.sid):match(" sta ")
end

function wifidev.is_ac(self)
	return (tonumber(sys.exec("db -q get hw.%s.is_ac" %self:version())) == 1)
end

function wifidev.countries(self)
	local countries = {}
	local code, cntry
	for line in utl.execi("wlctl -i %s country list | grep -v countries" %self.sid) do
		if line then
			code = line:match("(%S+)%s+%S*")
			if code == "EU" then
				code = "EU/13"
				cntry = "EUROPEAN UNION"
			else
				cntry = line:sub(4)
			end
			if code and cntry and cntry ~= "" and code ~= cntry then
				countries[code] = cntry
			end
		end
	end
	return countries
end

function wifidev.bands(self)
	return sys.exec("db -q get hw.%s.bands" %self:version()) or sys.exec("wlctl -i %q bands" %self.sid)
end

function wifidev.band(self)
	return sys.exec("wlctl -i %q band" %self.sid)
end

function wifidev.is_2g(self)
	return self:bands():match("b") or self:band():match("b")
end

function wifidev.is_5g(self)
	return self:bands():match("a") or self:band():match("a")
end

function wifidev.frequency(self)
	return self:bands():match("a") and "5GHz" or "2.4GHz"
end

function wifidev.channel(self)
	return tonumber(sys.exec("wlctl -i %q status | grep Primary | awk '{print$NF}'" %self.sid)) or 1
end

function wifidev.channels(self, country, band, bwidth)
	if nfs.access("/tmp/wireless/%s_chanspecs" %self.sid) then
		return utl.execi("cat /tmp/wireless/%s_chanspecs" %self.sid)
	end
	local cntry = utl.split(country, "/")
	local bnd = "2"
	if band == "a" then
		bnd = "5"
	end
	return utl.execi("wlctl -i %q chanspecs -c %s -b %s -w %s | awk '{print$1}'" %{self.sid, cntry[1], bnd, bwidth})
end

function wifidev.hwmodes(self)
	local B = false
	local G = false
	local N = false
	local AC = false
	if self:is_2g() then
		B = true
		G = true
		N = true
	end
	if self:is_5g() then
		N = true
		AC = self:is_ac()
	end
	return { b = B, g = G, n = N, ac = AC }
end

function wifidev.antenna(self)
	local ta = (sys.exec("wlctl -i %q txant 2>/dev/null" %self.sid) ~= "")
	local ra = (sys.exec("wlctl -i %q antdiv 2>/dev/null" %self.sid) ~= "")
	return { txant = ta, rxant = ra }
end

function wifidev.get_i18n(self)
	local x = self.sid
	local t = "Generic"
	if x:match("^wl%d") then
		t = "Broadcom"
	elseif x == "madwifi" then
		t = "Atheros"
	end

	local m = ""
	local l = self:hwmodes()
	if l.a then m = m .. "a" end
	if l.b then m = m .. "b" end
	if l.g then m = m .. "g" end
	if l.n then m = m .. "n" end
	if l.ac then m = m .. "ac" end

	return "%s 802.11%s Wireless Controller (%s)" %{ t, m, self:name() }
end

function wifidev.is_up(self)
	local up = false

	_uci_state:foreach("wireless", "wifi-iface",
		function(s)
			if s.device == self.sid then
				if s.up == "1" then
					up = true
					return false
				end
			end
		end)

	return up
end

function wifidev.radio(self)
	local up = false

	if self:get("radio") ~= "off" then
		up = true
	end

	return up
end

function wifidev.get_wifinet(self, net)
	if _uci_real:get("wireless", net) == "wifi-iface" then
		return wifinet(net)
	else
		local wnet = _wifi_lookup(net)
		if wnet then
			return wifinet(wnet)
		end
	end
end

function wifidev.get_wifinets(self)
	local nets = { }

	_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.device == self.sid then
				nets[#nets+1] = wifinet(s['.name'])
			end
		end)

	return nets
end

function wifidev.add_wifinet(self, options)
	options = options or { }
	options.device = self.sid

	local wnet = _uci_real:section("wireless", "wifi-iface", nil, options)
	if wnet then
		return wifinet(wnet, options)
	end
end

function wifidev.del_wifinet(self, net)
	if utl.instanceof(net, wifinet) then
		net = net.sid
	elseif _uci_real:get("wireless", net) ~= "wifi-iface" then
		net = _wifi_lookup(net)
	end

	if net and _uci_real:get("wireless", net, "device") == self.sid then
		_uci_real:delete("wireless", net)
		return true
	end

	return false
end


wifinet = utl.class()

function wifinet.__init__(self, net, data)
	self.sid = net

	local num = { }
	local netid
	_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.device then
				num[s.device] = num[s.device] and num[s.device] + 1 or 1
				if s['.name'] == self.sid then
					netid = "%s.network%d" %{ s.device, num[s.device] }
					return false
				end
			end
		end)

	local dev = _uci_state:get("wireless", self.sid, "ifname") or netid

	self.netid  = netid
	self.wdev   = dev
	self.iwinfo = dev and sys.wifi.getiwinfo(dev) or { }
	self.iwdata = data or _uci_state:get_all("wireless", self.sid) or
		_uci_real:get_all("wireless", self.sid) or { }
end

function wifinet.get(self, opt)
	return _get("wireless", self.sid, opt)
end

function wifinet.set(self, opt, val)
	return _set("wireless", self.sid, opt, val)
end

function wifinet.mode(self)
	return _uci_state:get("wireless", self.sid, "mode") or "ap"
end

function wifinet.ssid(self)
	return _uci_state:get("wireless", self.sid, "ssid")
end

function wifinet.bssid(self)
	return _uci_state:get("wireless", self.sid, "bssid")
end

function wifinet.network(self)
	return _uci_state:get("wifinet", self.sid, "network")
end

function wifinet.id(self)
	return self.netid
end

function wifinet.name(self)
	return self.sid
end

function wifinet.ifname(self)
	local num = { }
	local nid
	local ifname
	local found = false
	_uci_real:foreach("wireless", "wifi-iface",
		function(s)
			if s.device and not found then
				num[s.device] = num[s.device] and num[s.device] + 1 or 1
				if s['.name'] == self.sid then
					nid = num[s.device] - 1
					if nid == 0 then
						ifname = "%s" %{ s.device }
					else
						ifname = "%s.%d" %{ s.device, nid }
					end
					found = true
				end
			end
		end)
	return ifname
end

function wifinet.get_device(self)
	if self.iwdata.device then
		return wifidev(self.iwdata.device)
	end
end

function wifinet.is_up(self)
	return (self.iwdata.up == "1")
end

function wifinet.active_mode(self)
	local m = _stror(self.iwinfo.mode, self.iwdata.mode) or "ap"

	if     m == "ap"      then m = "Master"
	elseif m == "sta"     then m = "Client"
	elseif m == "adhoc"   then m = "Ad-Hoc"
	elseif m == "mesh"    then m = "Mesh"
	elseif m == "monitor" then m = "Monitor"
	end

	return m
end

function wifinet.active_mode_i18n(self)
	return lng.translate(self:active_mode())
end

function wifinet.active_ssid(self)
	--local ssid = "%s" %sys.exec("wlctl -i %q ssid | awk '{print$3}'" %self:ifname())
	--return ssid:gsub('"', '')
	return _uci_state:get("wireless", self.sid, "ssid")
end

function wifinet.active_bssid(self)
	local bssid = "%s" %sys.exec("wlctl -i %q bssid" %self:ifname())
	return bssid
end

function wifinet.active_encryption(self)
	local wep = "%d" %sys.exec("wlctl -i %q wepstatus" %self:ifname())
	local wpa = tonumber(sys.exec("wlctl -i %q wpa_auth | awk -F' ' '{print$1}'" %self:ifname()))
	local auth = "%d" %sys.exec("wlctl -i %q auth" %self:ifname())

	if wpa == 4 then
		return "WPA-PSK"
	elseif wpa == 128 then
		return "WPA2-PSK"
	elseif wpa == 132 then
		return "WPA/WPA2-PSK Mixed"
	elseif wpa == 2 then
		return "WPA-EAP"
	elseif wpa == 64 then
		return "WPA2-EAP"
	elseif wpa == 66 then
		return "WPA/WPA2-EAP Mixed"
	elseif wep == "1" and auth == "0" then
		return "WEP Open System"
	elseif wep == "1" and auth == "1" then
		return "WEP Shared Key"
	else
		return "No Encryption"
	end
end

function wifinet.frequency(self)
--	freqs = {"2.412", "2.417", "2.422", "2.427", "2.432", "2.437", "2.442", "2.447", "2.452", "2.457", "2.462", "2.467", "2.472", "2.484"}
--	return freqs[self:channel()]
	return (tonumber(self:channel()) >= 36) and "5" or "2.4"
end

function wifinet.bitrate(self)
	return sys.exec("wlctl -i %q rate | awk -F' ' '{print$1}'" %self:ifname())
end

function wifinet.channel(self)
	return tonumber(sys.exec("wlctl -i %q status | grep Primary | awk '{print$NF}'" %self:ifname())) or 1
end

function wifinet.signal(self)
	return sys.exec("wlctl -i %q status | grep 'RSSI' | awk -F' ' '{print$4}'" %self:ifname()) or 0
end

function wifinet.noise(self)
	return sys.exec("wlctl -i %q noise" %self:ifname()) or sys.exec("wlctl -i %q assoc | grep Mode: | awk '{print$10}'" %self:ifname()) or 0
end

function wifinet.rssi(self, sta)
	return sys.exec("wlctl -i %q rssi %s" %{self:ifname(), sta}) or 0
end

function wifinet.assoclist(self)
        assoctable = {}
        for bssid in utl.execi("wlctl -i %q assoclist | awk '{print$2}'" %self:ifname()) do
		assoctable[bssid] = {}
		assoctable[bssid]['signal'] = self:rssi(bssid)
		assoctable[bssid]['noise'] = self:noise()
		assoctable[bssid]['channel'] = self:channel()
        end
	return assoctable
end

function wifinet.country(self)
	local cntwlc = sys.exec("wlctl -i %q country | awk '{print$2}' | tr -d '()'" %self:ifname())
	local cntuci = sys.exec("uci get wireless.%s.country | cut -d'/' -f1" %self:get("device"))
	local country = cntwlc:match("(%S+)/%d+") or cntuci
	return country or "UNKNOWN"
end

function wifinet.txpower(self)
	local pwr_percent = (sys.exec("wlctl -i %q pwr_percent | awk -F' ' '{print$1}'" %self:ifname()) or 100)
	return pwr_percent
end

function wifinet.txpower_offset(self)
	return self.iwinfo.txpower_offset or 0
end

function wifinet.signal_level(self, s, n)
	if self:active_bssid() ~= "00:00:00:00:00:00" then
		local signal = s or self:signal()
		local noise  = n or self:noise()

		if signal < 0 and noise < 0 then
			local snr = -1 * (noise - signal)
			return math.floor(snr / 5)
		else
			return 0
		end
	else
		return -1
	end
end

function wifinet.signal_percent(self)
	local qc = self.iwinfo.quality or 0
	local qm = self.iwinfo.quality_max or 0

	if qc > 0 and qm > 0 then
		return math.floor((100 / qm) * qc)
	else
		return 0
	end
end

function wifinet.shortname(self)
	return "%s %q" %{
		lng.translate(self:active_mode()),
		self:active_ssid() or self:active_bssid()
	}
end

function wifinet.get_i18n(self)
	return "%s: %s %q (%s)" %{
		lng.translate("Wireless Network"),
		lng.translate(self:active_mode()),
		self:active_ssid() or self:active_bssid(),
		self:ifname()
	}
end

function wifinet.adminlink(self)
	return dsp.build_url("admin", "network", "wireless", self.netid)
end

function wifinet.get_network(self)
	return self:get_networks()[1]
end

function wifinet.get_networks(self)
	local nets = { }
	local net
	for net in utl.imatch(tostring(self.iwdata.network)) do
		if _uci_real:get("network", net) == "interface" then
			nets[#nets+1] = network(net)
		end
	end
	table.sort(nets, function(a, b) return a.sid < b.sid end)
	return nets
end

function wifinet.get_interface(self)
	return interface(self:ifname())
end


-- setup base protocols
_M:register_protocol("static")
_M:register_protocol("dhcp")
_M:register_protocol("none")

-- load protocol extensions
local exts = nfs.dir(utl.libpath() .. "/model/network")
if exts then
	local ext
	for ext in exts do
		if ext:match("%.lua$") then
			require("luci.model.network." .. ext:gsub("%.lua$", ""))
		end
	end
end
