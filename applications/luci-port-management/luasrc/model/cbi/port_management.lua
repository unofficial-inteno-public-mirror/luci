local sys = require "luci.sys"
local utl = require "luci.util"

local PORTS = utl.execi("db get hw.board.ethernetPortOrder | tr ' ' '\n'")

m = Map("ports", translate("Port Management"))



function interfacename(port)
	local intfname = sys.exec(". /lib/network/config.sh && interfacename %s" %port)
	if intfname:len() > 0 then
		return intfname
	end
	return nil
end

function is_ethwan(port)
	return (sys.exec("uci get layer2_interface_ethernet.Wan.baseifname"):match(port))
end



s = m:section(TypedSection, "ethport", translate("Ports"))
s.addremove = false
s.anonymous = true
s.template = "cbi/tblsection"

port = s:option(DummyValue, "name", translate("Port name"))

speed = s:option(ListValue, "speed", translate("Port speed"))
speed:value("auto", "Full auto-negotiation")
speed:value("100FDAUTO", "Max 100Mb auto-negotiation, full duplex")
speed:value("100HDAUTO", "Max 100Mb auto-negotiation, half duplex")
speed:value("10FDAUTO", "Max 10Mb auto-negotiation, full duplex")
speed:value("10HDAUTO", "Max 10Mb auto-negotiation, half duplex")
speed:value("100FD", "Only 100Mb, Full Duplex")
speed:value("100HD", "Only 100Mb, Half Duplex")
speed:value("10FD" , "Only 10Mb,  Full Duplex")
speed:value("10HD" , "Only 10Mb,  Half Duplex")
speed:value("disabled" , "Disabled")

pause = s:option(Flag, "pause", "Enable pause frame")



return m

