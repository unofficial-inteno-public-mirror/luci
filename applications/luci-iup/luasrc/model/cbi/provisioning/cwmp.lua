local net = require "luci.model.network".init()
local bit = require "bit"
local uci = require("luci.model.uci").cursor()

m = Map("cwmp",translate("TR-069"))

function m.parse(map)
	if m:formvalue("cbid.cwmp.acs.__rpc") then
		luci.sys.exec("ubus call tr069 inform '{\"GetRPCMethods\": true}'")
		luci.http.redirect(luci.dispatcher.build_url("admin/system/iup/cwmp"))
		return
	end
	Map.parse(map)
end

s = m:section(NamedSection, "acs",  translate("Configure ACS specific settings"),translate("Configure ACS specific settings"))
s.addremove = false
s.anonymous = false

n = s:option(Value, "userid", translate("ACS User Name"))
n = s:option(Value, "passwd",translate("ACS Password") )
n = s:option(Flag, "periodic_inform_enable",translate("Periodic Inform Enable") )
n.rmempty=false
n.enabled="true" and "1"
n.disabled = "false" and "0"
n = s:option(Flag, "dhcp_discovery",translate("DHCP Discovery"), translate("Use option 43 to find URL of ACS"))
n.enable="enable"
n.disabled = "disable"
n = s:option(Value, "url", translate("URL"))

n = s:option(Value, "periodic_inform_interval",translate("Periodic Inform Interval") )

if m.uci:get("cwmp", "acs", "url") ~= nil then
rpc = s:option(Button, "__rpc")
rpc.title      = translate(" ")
rpc.inputtitle = translate("Get RPC Methods")
rpc.inputstyle = "apply"
end

s = m:section(NamedSection, "cpe",  translate("Configure CPE specific settings"),translate("Configure CPE specific settings"))
s.addremove = false
s.anonymous = false

iface = s:option(ListValue, "default_wan_interface", translate("WAN Interface"))
uci:foreach("network", "interface",
	function (section)
		local ifc = section[".name"]
		local islan = section["is_lan"]
		if ifc ~= "loopback" and islan ~= "1" then
			iface:value(ifc)
		end
	end)
n = s:option(Value, "userid",translate("Connection Request User Name") )
n = s:option(Value, "passwd",translate("Connection Request User Password") )  
n = s:option(Value, "port",translate("Port") )

return m
