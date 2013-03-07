module("luci.controller.admin.layer2_interface_vdsl", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("layer2_interface_vdsl")
	
	local page = entry({"admin", "network", "layer2_interface", "layer2_interface_vdsl"}, cbi("admin_network/layer2_interface_vdsl"), luci.i18n.translate("VDSL"))
	page.i18n = "layer2_interface_vdsl"
	page.dependent = true
end
