module("luci.controller.admin.layer2_interface", package.seeall)

function index()
	entry({"admin", "network", "layer2_interface"}, cbi("admin_network/layer2_interface"), "Layer2Interface", 81)
	entry({"admin", "network", "layer2_interface", "layer2_interface_vlan"}, cbi("admin_network/layer2_interface_vlan"), "VLAN", 1)  
	entry({"admin", "network", "layer2_interface", "layer2_interface_adsl"}, cbi("admin_network/layer2_interface_adsl"), "ADSL", 2)
	entry({"admin", "network", "layer2_interface", "layer2_interface_vdsl"}, cbi("admin_network/layer2_interface_vdsl"), "VDSL", 3)
	entry({"admin", "network", "layer2_interface", "layer2_interface_ethernet"}, cbi("admin_network/layer2_interface_ethernet"), "Ethernet", 4)
	entry({"admin", "network", "layer2_interface", "layer2_interface"}, cbi("admin_network/layer2_interface"), "xDSL Settings", 5)
end
