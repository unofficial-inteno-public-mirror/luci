function index()
        local ubus = require "ubus".connect()
        local specs=ubus:call("router", "quest", { info = "specs" })
        ubus:close()
        entry({"admin", "network", "layer2_interface"}, cbi("admin_network/layer2_interface"), "Layer 2 Interfaces", 11)
        entry({"admin", "network", "layer2_interface", "layer2_interface"}, cbi("admin_network/layer2_interface"), "xDSL Settings", 1)
        entry({"admin", "network", "layer2_interface", "layer2_interface_vlan"}, cbi("admin_network/layer2_interface_vlan"), "VLAN", 2)
        entry({"admin", "network", "layer2_interface", "layer2_interface_adsl"}, cbi("admin_network/layer2_interface_adsl"), "ADSL", 3)
        if not specs then
                entry({"admin", "network", "layer2_interface", "layer2_interface_vdsl"}, cbi("admin_network/layer2_interface_vdsl"), "VDSL", 4)
                else
                if specs.vdsl
                then
                entry({"admin", "network", "layer2_interface", "layer2_interface_vdsl"}, cbi("admin_network/layer2_interface_vdsl"), "VDSL", 4)
                end
        end                                                                                                                                        
        entry({"admin", "network", "layer2_interface", "layer2_interface_ethernet"}, cbi("admin_network/layer2_interface_ethernet"), "Ethernet", 5)
end




