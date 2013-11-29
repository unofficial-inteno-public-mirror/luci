local sys = require "luci.sys"

m = Map("ports", translate("Port Management"))

s = m:section(TypedSection, "ethports", "Ethernet Ports")
s.anonymous = true

function interfacename(port)
	return sys.exec(". /lib/network/config.sh && interfacename %s" %port) or " "
end

eth0 = s:option(ListValue, "eth0", translate("eth0 (%s)" %interfacename("eth0")))
eth0:value("auto", "Auto-negotiation")
--eth0:value("1000FD", "1000Mb, Full Duplex")
--eth0:value("1000HD", "1000Mb, Half Duplex")
eth0:value("100FD", "100Mb, Full Duplex")
eth0:value("100HD", "100Mb, Half Duplex")
eth0:value("10FD" , "10Mb,  Full Duplex")
eth0:value("10HD" , "10Mb,  Half Duplex")

eth1 = s:option(ListValue, "eth1", translate("eth1 (%s)" %interfacename("eth1")))
eth1:value("auto", "Auto-negotiation")
--eth1:value("1000FD", "1000Mb, Full Duplex")
--eth1:value("1000HD", "1000Mb, Half Duplex")
eth1:value("100FD", "100Mb, Full Duplex")
eth1:value("100HD", "100Mb, Half Duplex")
eth1:value("10FD" , "10Mb,  Full Duplex")
eth1:value("10HD" , "10Mb,  Half Duplex")

eth2 = s:option(ListValue, "eth2", translate("eth2 (%s)" %interfacename("eth2")))
eth2:value("auto", "Auto-negotiation")
--eth2:value("1000FD", "1000Mb, Full Duplex")
--eth2:value("1000HD", "1000Mb, Half Duplex")
eth2:value("100FD", "100Mb, Full Duplex")
eth2:value("100HD", "100Mb, Half Duplex")
eth2:value("10FD" , "10Mb,  Full Duplex")
eth2:value("10HD" , "10Mb,  Half Duplex")

eth3 = s:option(ListValue, "eth3", translate("eth3 (%s)" %interfacename("eth3")))
eth3:value("auto", "Auto-negotiation")
--eth3:value("1000FD", "1000Mb, Full Duplex")
--eth3:value("1000HD", "1000Mb, Half Duplex")
eth3:value("100FD", "100Mb, Full Duplex")
eth3:value("100HD", "100Mb, Half Duplex")
eth3:value("10FD" , "10Mb,  Full Duplex")
eth3:value("10HD" , "10Mb,  Half Duplex")

eth4 = s:option(ListValue, "eth4", translate("eth4 (%s)" %interfacename("eth4")))
eth4:value("auto", "Auto-negotiation")
--eth4:value("1000FD", "1000Mb, Full Duplex")
--eth4:value("1000HD", "1000Mb, Half Duplex")
eth4:value("100FD", "100Mb, Full Duplex")
eth4:value("100HD", "100Mb, Half Duplex")
eth4:value("10FD" , "10Mb,  Full Duplex")
eth4:value("10HD" , "10Mb,  Half Duplex")

return m

