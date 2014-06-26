--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: qos.lua 9417 2012-11-10 20:55:50Z soma $
]]--

local wa = require "luci.tools.webadmin"
local fs = require "nixio.fs"

--m = Map("qos", translate("Quality of Service"),
--	translate("With <abbr title=\"Quality of Service\">QoS</abbr> you " ..
--		"can prioritize network traffic selected by addresses, " ..
--		"ports or services."))

m = Map("qos", translate("Quality of Service"),
	translate("With <abbr title=\"Quality of Service\">QoS</abbr> you " ..
		"can prioritize network traffic selected by IP precedence, addresses, protocols or ports.") .. "<br />" ..
		translate("Note: Each IP precedence value corresponds to single/multiple DSCP value(s) " ..
		"according to redefined Type of Service (ToS) field."))

--s = m:section(TypedSection, "interface", translate("Interfaces"))
--s.addremove = true
--s.anonymous = false

--e = s:option(Flag, "enabled", translate("Enable"))
--e.rmempty = false

--c = s:option(ListValue, "classgroup", translate("Classification group"))
--c:value("Default", translate("default"))
--c.default = "Default"

--s:option(Flag, "overhead", translate("Calculate overhead"))

--s:option(Flag, "halfduplex", translate("Half-duplex"))

--dl = s:option(Value, "download", translate("Download speed (kbit/s)"))
--dl.datatype = "and(uinteger,min(1))"

--ul = s:option(Value, "upload", translate("Upload speed (kbit/s)"))
--ul.datatype = "and(uinteger,min(1))"

s = m:section(TypedSection, "classify", translate("Classification Rules"))
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.sortable  = true

t = s:option(ListValue, "target", translate("Target"))
t:value("Priority", translate("priority"))
t:value("Express", translate("express"))
t:value("Normal", translate("normal"))
t:value("Bulk", translate("low"))
t.default = "Normal"

dscp = s:option(ListValue, "dscp", translate("Precedence"))
dscp.rmempty = true
dscp:value("", translate("all"))
dscp:value("0", "0")
dscp:value("8 10 12 14", "1")
dscp:value("16 18 20 22", "2")
dscp:value("24 26 28 30", "3")
dscp:value("32 34 36 38", "4")
dscp:value("40 46", "5")
dscp:value("48", "6")
dscp:value("56", "7")

--tos = s:option(ListValue, "tos", translate("IP Precedence"))
--tos.rmempty = true
--tos:value("", translate("all"))
--tos:value("0", "0")
--tos:value("32 40 56", "1")
--tos:value("72 88", "2")
--tos:value("96 112", "3")
--tos:value("136 144 152", "4")
--tos:value("160 184", "5")
--tos:value("192", "6")
--tos:value("224", "7")

srch = s:option(Value, "srchost", translate("Source host"))
srch.rmempty = true
srch:value("", translate("all"))
wa.cbi_add_knownips(srch)

dsth = s:option(Value, "dsthost", translate("Destination host"))
dsth.rmempty = true
dsth:value("", translate("all"))
wa.cbi_add_knownips(dsth)

--l7 = s:option(ListValue, "layer7", translate("Service"))
--l7.rmempty = true
--l7:value("", translate("all"))

--local pats = io.popen("find /etc/l7-protocols/ -type f -name '*.pat'")
--if pats then
--	local l
--	while true do
--		l = pats:read("*l")
--		if not l then break end

--		l = l:match("([^/]+)%.pat$")
--		if l then
--			l7:value(l)
--		end
--	end
--	pats:close()
--end

p = s:option(Value, "proto", translate("Protocol"))
p:value("", translate("all"))
p:value("tcp", "TCP")
p:value("udp", "UDP")
p:value("icmp", "ICMP")
p.rmempty = true

ports = s:option(Value, "ports", translate("Ports"))
ports.rmempty = true
ports:value("", translate("all"))

--bytes = s:option(Value, "connbytes", translate("Number of bytes"))

return m
