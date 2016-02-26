local net = require "luci.model.network".init()
local bus = require "ubus"
local bit = require "bit"
local uci = require("luci.model.uci").cursor()

m = Map("mcpd",translate("IGMP Proxy"))


s = m:section(TypedSection, "mcpd",  translate("Configure IGMP proxy specific parameters"))
s.addremove = false
s.anonymous = true

dscp = s:option(ListValue, "igmp_dscp_mark", translate("Differentiated services code point"),
("will be used to mark all outgoing IGMP packets"))
dscp:value("", " ")
dscp:value("CS0")	-- 0
dscp:value("CS1")	-- 8
dscp:value("AF11")	-- 10
dscp:value("AF12")	-- 12
dscp:value("AF13")	-- 14
dscp:value("CS2")	-- 16
dscp:value("AF21")	-- 18
dscp:value("AF22")	-- 20
dscp:value("AF23")	-- 22
dscp:value("CS3")	-- 24
dscp:value("AF31")	-- 26
dscp:value("AF32")	-- 28
dscp:value("AF33")	-- 30
dscp:value("CS4")	-- 32
dscp:value("AF41")	-- 34
dscp:value("AF42")	-- 36
dscp:value("AF43")	-- 38
dscp:value("CS5")	-- 40
dscp:value("EF")	-- 46
dscp:value("CS6")	-- 48
dscp:value("CS7")	-- 56

iface = s:option(MultiValue, "igmp_proxy_interfaces", translate("IGMP proxy interfaces"))
uci:foreach("network", "interface",
	function (section)
		local ifc = section[".name"]
		local islan = section["is_lan"]
		local typ = section["type"]
		local ifname = section["ifname"]
		if ifc ~= "loopback" and islan ~= "1" and typ ~= "alias" and (ifname and not ifname:match("^@")) then
			iface:value(ifc)
		end
	end)

n = s:option(ListValue, "igmp_default_version", translate("Default version"),
("Choose default version from list"))
n:value("1", "1")
n:value("2", "2")
n:value("3", "3")

n = s:option(Value, "igmp_query_interval",translate("Query interval") )
n = s:option(Value, "igmp_query_response_interval",translate("Query response interval") )
n = s:option(Value, "igmp_last_member_query_interval",translate("Last member query interval "))
n = s:option(Value, "igmp_robustness_value",translate("Robustness value") )

n = s:option(Flag, "igmp_lan_to_lan_multicast",translate("LAN to LAN multicast"),
("Check box to enable LAN to LAN multicast"))
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

n = s:option(Flag, "igmp_ssm_range_ignore", translate("Ignore SSM Range"),
translate("Check box to ignore SSM RFC to enable regular multicast on SSM-Range"))
n.enabled="1"
n.disabled="0"

n = s:option(ListValue, "igmp_snooping_enable",translate("IGMP snooping mode"),
("Choose snooping mode"))
n:value("0", "Disabled")
n:value("1", "Standard")
n:value("2", "Blocking")

function deviceof(intface)
	local _ubus
	local _ubuscache = { }

	_ubus = bus.connect()
	_ubuscache[intface] = _ubus:call("network.interface.%s" %intface, "status", {})
	_ubus:close()

	if _ubuscache[intface] then
		return _ubuscache[intface]["device"] or _ubuscache[intface]["l3_device"] or ""
	end
end

snpifaces = s:option(MultiValue, "igmp_snooping_interfaces", translate("IGMP snooping interfaces"))
uci:foreach("network", "interface",
	function (section)
		local ifc = section[".name"]
		local typ = section["type"]
		local islan = section["is_lan"]
		if ifc ~= "loopback" and typ ~= "alias" and (islan == "1" or typ == "bridge") then
			snpifaces:value(deviceof(ifc), ifc)
		end
	end)

return m

