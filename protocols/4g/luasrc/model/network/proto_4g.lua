local netmod = luci.model.network

local _, p
for _, p in ipairs({"4g"}) do

	local proto = netmod:register_protocol(p)

	function proto.get_i18n(self)
		if p == "4g" then
			return luci.i18n.translate("LTE")
		end
	end

	function proto.is_installed(self)
		if p == "4g" then
			return (nixio.fs.glob("/lib/netifd/proto/4g.sh")() ~= nil)
		end
	end
end
