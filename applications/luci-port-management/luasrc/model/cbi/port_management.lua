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
			eth:value("auto", "Auto-negotiation")
			--eth:value("1000FD", "1000Mb, Full Duplex")
			--eth:value("1000HD", "1000Mb, Half Duplex")
			eth:value("100FD", "100Mb, Full Duplex")
			eth:value("100HD", "100Mb, Half Duplex")
			eth:value("10FD" , "10Mb,  Full Duplex")
			eth:value("10HD" , "10Mb,  Half Duplex")
			if ADMINST then
				eth:value("disabled" , "Disabled")
			end
		end
	end
end

return m

