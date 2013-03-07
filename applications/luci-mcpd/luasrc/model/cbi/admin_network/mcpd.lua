local net = require "luci.model.network".init()
m = Map("mcpd",translate("IGMP Proxy"))


local bit = require "bit"

s = m:section(TypedSection, "mcpd",  translate("Configure Igmp proxy specific parameters"))
s.addremove = false
s.anonymous = true

iface = s:option(ListValue, "igmp_proxy_interfaces", translate("Wan igmp proxy interfaces"))
local ifcs = net:get_layer2interfaces()
		if ifcs then
			local _, ifn
		
			for _, ifn in ipairs(ifcs) do
				iface:value(ifn:name(), translate(ifn:layer2name()))
			end
		end	

n = s:option(ListValue, "igmp_default_version", translate("Default version"),
("Choose default version from list"))
n:value("1", "1")
n:value("2", "2")
n:value("3", "3")

n = s:option(Value, "igmp_query_interval",translate("Query interval") )
n = s:option(Value, "igmp_query_response_interval",translate("Query response interval") )
n = s:option(Value, "igmp_last_member_query_interval",translate("Last member query interval "))
n = s:option(Value, "igmp_robustness_value",translate("Robustness value") )

n = s:option(Flag, "igmp_lan_to_lan_multicast",translate("Lan to lan multicast"),
("Check box to enable Lan to lan multicast"))
n.enabled="1"                                                                                
n.disabled="0"

n = s:option(Value, "igmp_max_groups",translate("Max groups") )
n = s:option(Value, "igmp_max_sources",translate("Max sources") )
n = s:option(Value, "igmp_max_members",translate("Max members") )

n = s:option(Flag, "igmp_fast_leave",translate("Fast leave"),
("Check box to enable fast leave"))
n.enabled="1"                                             
n.disabled="0"

n = s:option(Flag, "igmp_join_immediate",translate("Join immediate"),
("Check box to enable immediate join"))
n.enabled="1"
n.disabled="0"

n = s:option(Flag, "igmp_proxy_enable",translate("Proxy enable"),
("Check box to enable IGMP proxy"))
n.enabled="1"
n.disabled="0"
                                                                     
n = s:option(ListValue, "igmp_snooping_enable",translate("IGMP Snooping Mode"),
("Choose snooping mode"))
n:value("0", "Disabled")
n:value("1", "Standard")
n:value("2", "Blocking")
                                                                                                                                                    
n = s:option(Value, "igmp_snooping_interfaces",translate("IGMP snooping interfaces"))



return m



