module("luci.controller.admin.layer2_interface_ethernet", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("layer2_interface_ethernet")
	
	local page = entry({"admin", "network", "layer2_interface", "layer2_interface_ethernet"}, cbi("admin_network/layer2_interface_ethernet"), luci.i18n.translate("Ethernet"))
	page.i18n = "layer2_interface_ethernet"
	page.dependent = true
end
