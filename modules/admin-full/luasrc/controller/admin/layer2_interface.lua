module("luci.controller.admin.layer2_interface", package.seeall)

function index()
        local ubus = require "ubus".connect()
        local users = { "admin" }
        local specs

        if ubus then 
                specs = ubus:call("router", "quest", { info = "specs" })
                ubus:close()
        end

        for k, user in pairs(users) do
                if not specs or specs.adsl then
                        entry({user, "network", "layer2_interface"}, cbi("admin_network/layer2_interface"), "Layer 2 Interfaces", 11)
                else
                        entry({user, "network", "layer2_interface"}, cbi("admin_network/layer2_interface_ethernet"), "Layer 2 Interfaces", 11)
                end

                if not specs or specs.adsl then
                        entry({user, "network", "layer2_interface", "layer2_interface"}, cbi("admin_network/layer2_interface"), "xDSL Settings", 1)
                end
                	entry({user, "network", "layer2_interface", "layer2_interface_vlan"}, cbi("admin_network/layer2_interface_vlan"), "VLAN", 2)
                if not specs or specs.adsl then
                        entry({user, "network", "layer2_interface", "layer2_interface_adsl"}, cbi("admin_network/layer2_interface_adsl"), "ADSL", 3)
                end
                if not specs or specs.vdsl then
                        entry({user, "network", "layer2_interface", "layer2_interface_vdsl"}, cbi("admin_network/layer2_interface_vdsl"), "VDSL", 4)
                end                                                                                                                                        
                entry({user, "network", "layer2_interface", "layer2_interface_ethernet"}, cbi("admin_network/layer2_interface_ethernet"), "Ethernet", 5)
        end
end
