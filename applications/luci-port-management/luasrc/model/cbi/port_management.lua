local sys = require "luci.sys"
local utl = require "luci.util"

local PORTS = utl.execi("db get hw.board.ethernetPortOrder | tr ' ' '\n'")

m = Map("ports", translate("Port Management"))

s = m:section(TypedSection, "ethports", "Ethernet Ports")
s.anonymous = true

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

for eport in PORTS do
	if interfacename(eport) then
		if ADMINST or not sys.exec("uci -q get ports.@ethports[0].%s" %eport):match("disabled") then
			local detail = (TECUSER) and " (%s)" %eport or ""
			eth = s:option(ListValue, eport, "%s%s" %{interfacename(eport), detail})
			eth.rmempty = true
			eth:value("auto", "Full auto-negotiation")
			--eth:value("1000FDAUTO", "Max 1000Mb auto-negotiation, full duplex")
			--eth:value("1000HDAUTO", "Max 1000Mb auto-negotiation, half duplex")
			eth:value("100FDAUTO", "Max 100Mb auto-negotiation, full duplex")
			eth:value("100HDAUTO", "Max 100Mb auto-negotiation, half duplex")
			eth:value("10FDAUTO", "Max 10Mb auto-negotiation, full duplex")
			eth:value("10HDAUTO", "Max 10Mb auto-negotiation, half duplex")
			--eth:value("1000FD", "Only 1000Mb, Full Duplex")
			--eth:value("1000HD", "Only 1000Mb, Half Duplex")
			eth:value("100FD", "Only 100Mb, Full Duplex")
			eth:value("100HD", "Only 100Mb, Half Duplex")
			eth:value("10FD" , "Only 10Mb,  Full Duplex")
			eth:value("10HD" , "Only 10Mb,  Half Duplex")
			if ADMINST then
				eth:value("disabled" , "Disabled")
			end
		end
	end
end

return m

