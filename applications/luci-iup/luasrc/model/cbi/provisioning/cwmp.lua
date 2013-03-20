local net = require "luci.model.network".init()
m = Map("cwmp",translate("tr-069"))


local bit = require "bit"

s = m:section(NamedSection, "acs",  translate("Configure ACS specifc settings"),translate("Configure ACS specifc settings"))
s.addremove = false
s.anonymous = false



n = s:option(Value, "userid", translate("ACS User Name"))
n = s:option(Value, "passwd",translate("ACS Password") )
n = s:option(Flag, "periodic_inform_enable",translate("Periodic Inform Enable") )
n.enabled="true"
n.disabled = "false"
n = s:option(Flag, "dhcp_discovery",translate("Dhcp Discovery"), translate("Use option 43 to find URL of ACS"))
n.enable="enable"
n.disabled = "disable"
n = s:option(Value, "url",translate("URL") )

n = s:option(Value, "periodic_inform_interval",translate("Periodic Inform Interval") )

s = m:section(NamedSection, "cpe",  translate("Configure CPE specifc settings"),translate("Configure CPE specifc settings"))
s.addremove = false
s.anonymous = false

iface = s:option(ListValue, "interface", translate("Waninterfaces"))
local ifcs = net:get_layer2interfaces()
		if ifcs then
			local _, ifn
		
			for _, ifn in ipairs(ifcs) do
				iface:value(ifn:name(), translate(ifn:layer2name()))
			end
		end	

n = s:option(Value, "userid",translate("Connection Request User Name") )
n = s:option(Value, "passwd",translate("Connection Request User Password") )  
n = s:option(Value, "port",translate("Port") )




return m