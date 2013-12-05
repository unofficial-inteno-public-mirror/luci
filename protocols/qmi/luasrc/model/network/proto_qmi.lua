local netmod = luci.model.network

local _, p
for _, p in ipairs({"qmi"}) do

	local proto = netmod:register_protocol(p)

	function proto.get_i18n(self)
		if p == "qmi" then
			return luci.i18n.translate("LTE")
		end
	end

	function proto.ifname(self)
		return p .. "-" .. self.sid
	end

	function proto.is_installed(self)
		if p == "qmi" then
			return (nixio.fs.glob("/usr/lib/libqmi-glib.so")() ~= nil)
		end
	end

	function proto.is_floating(self)
		return (p ~= "qmi")
	end

	function proto.is_qmi(self)
		return true
	end

	function proto.get_interfaces(self)
		if self:is_floating() then
			return nil
		else
			return netmod.protocol.get_interfaces(self)
		end
	end

	function proto.contains_interface(self, ifc)
		if self:is_floating() then
			return (netmod:ifnameof(ifc) == self:ifname())
		else
			return netmod.protocol.contains_interface(self, ifc)
		end
	end

	netmod:register_pattern_virtual("^%s-%%w" % p)
end
