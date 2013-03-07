module("luci.controller.admin.layer2_interface_adsl", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("layer2_interface_adsl")
	
	local page = entry({"admin", "network", "layer2_interface", "layer2_interface_adsl"}, cbi("admin_network/layer2_interface_adsl"), luci.i18n.translate("ADSL"))
	page.i18n = "layer2_interface_adsl"
	page.dependent = true
end
