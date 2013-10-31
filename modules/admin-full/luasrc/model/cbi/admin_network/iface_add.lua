--[[
LuCI - Lua Configuration Interface

Copyright 2009-2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: iface_add.lua 9655 2013-01-27 18:43:41Z jow $

]]--

local nw  = require "luci.model.network".init()
local fw  = require "luci.model.firewall".init()
local utl = require "luci.util"
local uci = require "luci.model.uci".cursor()

m = SimpleForm("network", translate("Create Interface"))
m.redirect = luci.dispatcher.build_url("admin/network/network")
m.reset = false

newnet = m:field(Value, "_netname", translate("Name of the new interface"),
	translate("The allowed characters are: <code>A-Z</code>, <code>a-z</code>, " ..
		"<code>0-9</code> and <code>_</code>"
	))

newnet:depends("_attach", "")
newnet.default = arg[1] and "net_" .. arg[1]:gsub("[^%w_]+", "_")
newnet.datatype = "uciname"

newproto = m:field(ListValue, "_netproto", translate("Protocol of the new interface"))

netbridge = m:field(ListValue, "_bridge", translate("Set as"))
netbridge:value("", "standalone interface")
netbridge:value("1", "bridge over multiple interfaces")
netbridge:value("2", "bridge alias")
netbridge:value("3", "any WAN")


sifname = m:field(Value, "_ifname", translate("Cover the following interface"))

sifname.widget = "radio"
sifname.template  = "cbi/network_ifacelist"
sifname.nobridges = true


mifname = m:field(Value, "_ifnames", translate("Cover the following interfaces"))

mifname.widget = "checkbox"
mifname.template  = "cbi/network_ifacelist"
mifname.nobridges = true


aifname = m:field(Value, "_aifname", translate("Cover the following bridge"))

aifname.widget = "radio"
aifname.template  = "cbi/network_bridgelist"
aifname.nobridges = false

mwifname = m:field(Value, "_mwifnames", translate("Cover the following interfaces"))

mwifname.widget = "checkbox"
mwifname.template  = "cbi/network_wanifacelist"
mwifname.nobridges = true

local _, p
for _, p in ipairs(nw:get_protocols()) do
	if p:is_installed() then
		newproto:value(p:proto(), p:get_i18n())
		if not p:is_virtual()  then netbridge:depends("_netproto", p:proto()) end
		if not p:is_floating() then
			sifname:depends({ _bridge = "",  _netproto = p:proto()})
			mifname:depends({ _bridge = "1", _netproto = p:proto()})
			aifname:depends({ _bridge = "2", _netproto = p:proto()})
			mwifname:depends({ _bridge = "3", _netproto = p:proto()})
		end
	end
end

function newproto.validate(self, value, section)
	local name = newnet:formvalue(section)
	if not name or #name == 0 then
		newnet:add_error(section, translate("No network name specified"))
	elseif m:get(name) then
		newnet:add_error(section, translate("The given network name is not unique"))
	end

	local proto = nw:get_protocol(value)
	if proto and not proto:is_floating() then
		local br = (netbridge:formvalue(section) == "1")
		local al = (netbridge:formvalue(section) == "2")
		local mw = (netbridge:formvalue(section) == "3")
		local ifn = (br and mifname:formvalue(section)) or (al and aifname:formvalue(section)) or (mw and mwifname:formvalue(section)) or sifname:formvalue(section)
		
		-- check if selected interface is used by a bridge
		if ifn == (br and mifname:formvalue(section)) then
			local there, intface, ifname, typ, adv
			uci:foreach("network", "interface",
			function (s)
				if there then
					return
				end
				intface = s[".name"]
				typ = s["type"]
				ifname = s["ifname"]

				if typ  == "bridge" and ifname then
					for iface in ifname:gmatch("%S+") do
						for nif in utl.imatch(ifn) do
							if iface == nif then
								if there then 
									there = there .. ", " .. nif
									adv = "are"
								else
									there = nif
									adv = "is"
								end
							end
						end
					end
				end
			end)
			if there then
				return nil, translate("%s %s used by '%s'" %{there, adv, intface})
			end
		end

		for ifn in utl.imatch(ifn) do
			return value
		end
		return nil, translate("The selected protocol needs a device assigned")
	end
	return value
end

function newproto.write(self, section, value)
	local name = newnet:formvalue(section)
	if name and #name > 0 then
		local br = (netbridge:formvalue(section) == "1") and "bridge"
		local al = (netbridge:formvalue(section) == "2") and "alias"
		local mw = (netbridge:formvalue(section) == "3") and "anywan"
		local net = nw:add_network(name, { proto = value, type = br or al or mw or nil})
		if net then
			local ifn
			for ifn in utl.imatch(
				(br and mifname:formvalue(section)) or (al and aifname:formvalue(section)) or (mw and mwifname:formvalue(section)) or sifname:formvalue(section)
			) do
				net:add_interface(ifn)
			end
			nw:save("network")
			nw:save("wireless")
		end
		luci.http.redirect(luci.dispatcher.build_url("admin/network/network", name))
	end
end

return m
