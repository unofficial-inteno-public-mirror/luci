module("luci.controller.admin.mcpd", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("mcpd")
	
	local page = entry({"admin", "network", "mcpd"}, cbi("admin_network/mcpd"), luci.i18n.translate("IGMP Proxy"))
	page.i18n = "mcpd"
	page.dependent = true
end
