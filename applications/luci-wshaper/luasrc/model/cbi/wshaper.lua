--[[
LuCI - Lua Configuration Interface

Copyright 2011 Manuel Munz <freifunk at somakoma dot de>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

require("luci.tools.webadmin")

m = Map("wshaper", translate("Wondershaper"),
	translate("Wondershaper uses traffic shaping to ensure low latencies for interactive traffic even when your " ..
	"internet connection is highly saturated."))

s = m:section(NamedSection, "settings", "wshaper", translate("Wondershaper settings"))
s.anonymous = true

network = s:option(ListValue, "network", translate("Interface"))
luci.tools.webadmin.cbi_add_networks(network)

uplink = s:option(Value, "uplink", translate("Uplink"), translate("Upstream bandwidth in kbit/s"))
uplink.optional = false
uplink.datatype = "uinteger"
uplink.default = "240"

downlink = s:option(Value, "downlink", translate("Downlink"), translate("Downstream bandwidth in kbit/s"))
downlink.optional = false
downlink.datatype = "uinteger"
downlink.default = "200"

nopriohostsrc = s:option(DynamicList, "nopriohostsrc", translate("Low priority hosts (Source)"), translate("Host or Network in CIDR notation."))
nopriohostsrc.optional = true
nopriohostsrc.datatype = ipaddr
nopriohostsrc.placeholder = "10.0.0.1/32"

nopriohostdst = s:option(DynamicList, "nopriohostdst", translate("Low priority hosts (Destination)"), translate("Host or Network in CIDR notation."))
nopriohostdst.optional = true
nopriohostdst.datatype = ipaddr
nopriohostdst.placeholder = "10.0.0.1/32"

noprioportsrc = s:option(DynamicList, "noprioportsrc", translate("Low priority source ports"))
noprioportsrc.optional = true
noprioportsrc.datatype = "range(0,65535)"
noprioportsrc.placeholder = "21"

noprioportdst = s:option(DynamicList, "noprioportdst", translate("Low priority destination ports"))
noprioportdst.optional = true
noprioportdst.datatype = "range(0,65535)"
noprioportdst.placeholder = "21"

return m
