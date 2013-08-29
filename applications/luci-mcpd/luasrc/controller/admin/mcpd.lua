module("luci.controller.admin.mcpd", package.seeall)

function index()
	local page 
	
	page = entry({"admin", "network", "mcpd"}, cbi("admin_network/mcpd"), luci.i18n.translate("IGMP Proxy"))
	page.dependent = true

	page = entry({"admin", "status", "igmp"}, template("admin_status/igmp"), "IGMP Snooping")

end

