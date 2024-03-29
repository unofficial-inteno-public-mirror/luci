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

local function wlinfo(dev, mac)
	local rv = {}
	local ssid, net, ch, rssi, ns, sr
	ssid = luci.sys.exec("wlctl -i %q ssid" %dev):match("Current SSID: \"(%S+)\"") or ""
	ch = tonumber(luci.sys.exec("wlctl -i %q channel | grep mac | awk '{print$4}'" %dev)) or 0
	net = "%s <font size=\"1\"><b>%sGHz</b></font>" %{ssid, (ch >= 36) and "5"  or "2.4"}
	rssi = tonumber(luci.sys.exec("wlctl -i %q rssi %s" %{dev, mac})) or 0
	ns = tonumber(luci.sys.exec("wlctl -i %q noise" %dev)) or tonumber(luci.sys.exec("wlctl -i %q assoc | grep Mode: | awk '{print$10}'" %dev)) or 0
	sr = "%f" %((-1 * (ns - rssi)) / 5)
	rv = {
		channel = ch,
		network = net,
		signal = rssi,
		noise = ns,
		snr = sr
	}
	return rv
end

function ipv4_clients()
	local _ubus
	local _ubuscache = { }
	local rv = { }
	local i = 1
	local clntno = "client-%d" %i

        _ubus = bus.connect()
        _ubuscache["clients"] = _ubus:call("router", "connected", { })
        _ubus:close()

        while _ubuscache["clients"][clntno] do
                local ip = _ubuscache["clients"][clntno]["ipaddr"]
                local mac = _ubuscache["clients"][clntno]["macaddr"]
                local name = _ubuscache["clients"][clntno]["hostname"]
		local net = _ubuscache["clients"][clntno]["network"]
		local wireless = _ubuscache["clients"][clntno]["wireless"]
		local wdev = wireless and _ubuscache["clients"][clntno]["wdev"] or nil
		rv[#rv+1] = {
			macaddr  = mac:upper(),
			ipaddr   = ip,
			hostname = (name ~= "*") and name,
			network	 = net:upper(),
			is_sta	 = wireless,
			wlinfo	 = wireless and wlinfo(wdev, mac) or nil
		}
                i = i + 1
		clntno = "client-%d" %i
        end

	return rv
end

function ipv6_clients()
	local _ubus
	local _ubuscache = { }
	local rv = { }
	local i = 1
	local clntno = "client-%d" %i

        _ubus = bus.connect()
        _ubuscache["clients6"] = _ubus:call("router", "connected6", { })
        _ubus:close()

        while _ubuscache["clients6"][clntno] do
                local ip6 = _ubuscache["clients6"][clntno]["ip6addr"]
		local mac = _ubuscache["clients6"][clntno]["macaddr"]
                local du = _ubuscache["clients6"][clntno]["duid"]
                local name = _ubuscache["clients6"][clntno]["hostname"]
		local device = _ubuscache["clients6"][clntno]["device"]
		local net = device:match("br-") and device:sub(4) or ""
		local wireless = _ubuscache["clients6"][clntno]["wireless"]
		local wdev = wireless and _ubuscache["clients6"][clntno]["wdev"] or nil
		rv[#rv+1] = {
			macaddr  = mac:upper(),
			duid	 = (du ~= "*") and du,
			ip6addr	 = ip6,
			hostname = (name ~= "*") and name,
			network	 = net:upper(),
			is_sta	 = wireless,
			wlinfo	 = wireless and wlinfo(wdev, mac) or nil
		}
                i = i + 1
		clntno = "client-%d" %i
        end

	return rv
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
						}
					elseif family == 6 and ip:match(":") then
						rv[#rv+1] = {
							expires  = os.difftime(tonumber(ts) or 0, os.time()),
							ip6addr  = ip,
							duid     = (duid ~= "*") and duid,
							hostname = (name ~= "*") and name,
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
	local leasefile = "/tmp/hosts/odhcpd"
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
			frequency= dev:frequency(),
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
