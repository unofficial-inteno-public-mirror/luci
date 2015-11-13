--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2010 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: hosts.lua 9416 2012-11-10 17:38:37Z soma $
]]--

require("luci.sys")
require("luci.util")
local uci = require("luci.model.uci").cursor()
m = Map("dhcp", translate("Hostnames"))

s = m:section(TypedSection, "domain", translate("Host entries"))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

hn = s:option(DynamicList, "name", translate("Hostname"))
hn.datatype = "hostname"
hn.rmempty  = true

local lanip = uci:get("network", "lan", "ipaddr")
ip = s:option(Value, "ip", translate("IP address"))
ip.datatype = "ipaddr"
ip.rmempty  = true
ip.placeholder = lanip

local arptable = luci.sys.net.arptable() or {}
for i, dataset in ipairs(arptable) do
	ip:value(
		dataset["IP address"],
		"%s (%s)" %{ dataset["IP address"], dataset["HW address"] }
	)
end

function ip.write(self, section, value)
	if value == lanip then
		return nil
	end
	self.map:set(section, "ip", value)
end

return m
