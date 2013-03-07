module("luci.controller.admin.layer2_interface_vlan", package.seeall)

function index()
	require("luci.i18n")
	luci.i18n.loadc("layer2_interface_vlan")
	
	local page = entry({"admin", "network", "layer2_interface", "layer2_interface_vlan"}, cbi("admin_network/layer2_interface_vlan"), luci.i18n.translate("VLAN"))
	page.i18n = "layer2_interface_vlan"
	page.dependent = true
end
