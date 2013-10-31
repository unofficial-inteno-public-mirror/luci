--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.tools.status", package.seeall)

local uci = require "luci.model.uci".cursor()
local bus = require "ubus"

function is_associated(mac)
	local devices = luci.sys.exec("cat /proc/net/dev")
	for dev in devices:gmatch("(%S+):%s+%S*") do
		if dev:match("^wl%d") then
			local assoclist = luci.sys.exec("wlctl -i %q assoclist" %dev)
			for assoc in assoclist:gmatch("assoclist%s+(%S+)") do
				if assoc == mac:upper() then
					return 1
				end
			end
		end
	end
	return nil
end

function is_connected(ip, field)
	local _ubus
	local _ubuscache = { }

	_ubus = bus.connect()
	_ubuscache[ip] = _ubus:call("router", "host", { ipaddr = ip })
	_ubus:close()

	if _ubuscache[ip] and field then
		return _ubuscache[ip][field]
	else
		return 0
	end
end

local function dhcp_leases_common(family)
	local rv = { }
	local nfs = require "nixio.fs"
	local leasefile = "/var/dhcp.leases"

	uci:foreach("dhcp", "dnsmasq",
		function(s)
			if s.leasefile and nfs.access(s.leasefile) then
				leasefile = s.leasefile
				return false
			end
		end)

	local fd = io.open(leasefile, "r")
	if fd then
		while true do
			local ln = fd:read("*l")
			if not ln then
				break
			else
				local ts, mac, ip, name, duid = ln:match("^(%d+) (%S+) (%S+) (%S+) (%S+)")
				if ts and mac and ip and name and duid then
					if family == 4 and not ip:match(":") then
						rv[#rv+1] = {
							expires  = os.difftime(tonumber(ts) or 0, os.time()),
							macaddr  = mac,
							ipaddr   = ip,
							hostname = (name ~= "*") and name,
							status   = is_associated(mac) or is_connected(ip, "connected")
						}
					elseif family == 6 and ip:match(":") then
						rv[#rv+1] = {
							expires  = os.difftime(tonumber(ts) or 0, os.time()),
							ip6addr  = ip,
							duid     = (duid ~= "*") and duid,
							hostname = (name ~= "*") and name,
							status   = 1 --TODO
						}
					end
				end
			end
		end
		fd:close()
	end

	return rv
end

function dhcp_leases()
	return dhcp_leases_common(4)
end

function dhcp6_leases()
	local nfs = require "nixio.fs"
	local leasefile = "/tmp/hosts/6relayd"
	local rv = {}

	if nfs.access(leasefile, "r") then
		local fd = io.open(leasefile, "r")
		if fd then
			while true do
				local ln = fd:read("*l")
				if not ln then
					break
				else
					local iface, duid, iaid, name, ts, id, length, ip = ln:match("^# (%S+) (%S+) (%S+) (%S+) (%d+) (%S+) (%S+) (.*)")
					if ip then
						rv[#rv+1] = {
							expires  = os.difftime(tonumber(ts) or 0, os.time()),
							duid     = duid,
							ip6addr  = ip,
							hostname = (name ~= "-") and name
						}
					end
				end
			end
			fd:close()
		end
		return rv
	elseif luci.sys.call("dnsmasq --version 2>/dev/null | grep -q ' DHCPv6 '") == 0 then
		return dhcp_leases_common(6)
	end
end

function wifi_networks()
	local rv = { }
	local ntm = require "luci.model.network".init()

	local dev
	for _, dev in ipairs(ntm:get_wifidevs()) do
		local rd = {
			up       = dev:is_up(),
			device   = dev:name(),
			name     = dev:get_i18n(),
			networks = { }
		}

		local net
		for _, net in ipairs(dev:get_wifinets()) do
			rd.networks[#rd.networks+1] = {
				name       = net:shortname(),
				link       = net:adminlink(),
				up         = net:is_up(),
				mode       = net:active_mode(),
				ssid       = net:active_ssid(),
				bssid      = net:active_bssid(),
				encryption = net:active_encryption(),
				frequency  = net:frequency(),
				channel    = net:channel(),
				signal     = net:signal(),
				quality    = net:signal_percent(),
				noise      = net:noise(),
				bitrate    = net:bitrate(),
				ifname     = net:ifname(),
				assoclist  = net:assoclist(),
				country    = net:country(),
				txpower    = net:txpower(),
				txpoweroff = net:txpower_offset()
			}
		end

		rv[#rv+1] = rd
	end

	return rv
end

function wifi_network(id)
	local ntm = require "luci.model.network".init()
	local net = ntm:get_wifinet(id)
	if net then
		local dev = net:get_device()
		if dev then
			return {
				id         = id,
				name       = net:shortname(),
				link       = net:adminlink(),
				up         = net:is_up(),
				mode       = net:active_mode(),
				ssid       = net:active_ssid(),
				bssid      = net:active_bssid(),
				encryption = net:active_encryption(),
				frequency  = net:frequency(),
				channel    = net:channel(),
				signal     = net:signal(),
				quality    = net:signal_percent(),
				noise      = net:noise(),
				bitrate    = net:bitrate(),
				ifname     = net:ifname(),
				assoclist  = net:assoclist(),
				country    = net:country(),
				txpower    = net:txpower(),
				txpoweroff = net:txpower_offset(),
				device     = {
					up     = dev:is_up(),
					device = dev:name(),
					name   = dev:get_i18n()
				}
			}
		end
	end
	return { }
end

function switch_status(devs)
	local dev
	local switches = { }
	for dev in devs:gmatch("[^%s,]+") do
		local ports = { }
		local swc = io.popen("swconfig dev %q show" % dev, "r")
		if swc then
			local l
			repeat
				l = swc:read("*l")
				if l then
					local port, up = l:match("port:(%d+) link:(%w+)")
					if port then
						local speed  = l:match(" speed:(%d+)")
						local duplex = l:match(" (%w+)-duplex")
						local txflow = l:match(" (txflow)")
						local rxflow = l:match(" (rxflow)")
						local auto   = l:match(" (auto)")

						ports[#ports+1] = {
							port   = tonumber(port) or 0,
							speed  = tonumber(speed) or 0,
							link   = (up == "up"),
							duplex = (duplex == "full"),
							rxflow = (not not rxflow),
							txflow = (not not txflow),
							auto   = (not not auto)
						}
					end
				end
			until not l
			swc:close()
		end
		switches[dev] = ports
	end
	return switches
end
