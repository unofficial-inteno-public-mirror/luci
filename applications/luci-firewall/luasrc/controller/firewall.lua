module("luci.controller.firewall", package.seeall)

function index()
	local uci = require("luci.model.uci").cursor()
	local has_dmz = uci:get("firewall", "dmz")

	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do
		if user == "user" then
			entry({user, "network", "firewall"},
				alias(user, "network", "firewall", "forwards"),
				_("Firewall"), 60)
		else
			entry({user, "network", "firewall"},
				alias(user, "network", "firewall", "zones"),
				_("Firewall"), 60)

			entry({user, "network", "firewall", "zones"},
				arcombine(cbi("firewall/zones"), cbi("firewall/zone-details")),
				_("General Settings"), 10).leaf = true
		end

		entry({user, "network", "firewall", "forwards"},
			arcombine(cbi("firewall/forwards"), cbi("firewall/forward-details")),
			_("Port Forwards"), 20).leaf = true

		entry({user, "network", "firewall", "rules"},
			arcombine(cbi("firewall/rules"), cbi("firewall/rule-details")),
			_("Traffic Rules"), 30).leaf = true

--		entry({user, "network", "firewall", "custom"},
--			cbi("firewall/custom"),
--			_("Custom Rules"), 40).leaf = true

		if has_dmz then
			entry({user, "network", "firewall", "dmz"},
				cbi("firewall/dmz"),
				_("DMZ Host"), 50).leaf = true
		end
	end
end
