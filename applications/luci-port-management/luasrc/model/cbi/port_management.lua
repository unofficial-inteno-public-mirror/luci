local sys = require "luci.sys"

local PORTS = { "eth0", "eth1", "eth2", "eth3", "eth4" }

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

for _, eport in ipairs(PORTS) do
	if interfacename(eport) then
		eth = s:option(ListValue, eport, "%s (%s)" %{eport, interfacename(eport)})
		eth.rmempty = true
		eth:value("disabled", "Disabled")
		eth:value("auto", "Auto-negotiation")
		--eth:value("1000FD", "1000Mb, Full Duplex")
		--eth:value("1000HD", "1000Mb, Half Duplex")
		eth:value("100FD", "100Mb, Full Duplex")
		eth:value("100HD", "100Mb, Half Duplex")
		eth:value("10FD" , "10Mb,  Full Duplex")
		eth:value("10HD" , "10Mb,  Half Duplex")
	end
end

return m

