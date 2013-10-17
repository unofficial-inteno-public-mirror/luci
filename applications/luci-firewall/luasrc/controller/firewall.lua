module("luci.controller.firewall", package.seeall)

function index()
	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do
		entry({user, "network", "firewall"},
			alias(user, "network", "firewall", "zones"),
			_("Firewall"), 60)

		entry({user, "network", "firewall", "zones"},
			arcombine(cbi("firewall/zones"), cbi("firewall/zone-details")),
			_("General Settings"), 10).leaf = true

		entry({user, "network", "firewall", "forwards"},
			arcombine(cbi("firewall/forwards"), cbi("firewall/forward-details")),
			_("Port Forwards"), 20).leaf = true

		entry({user, "network", "firewall", "rules"},
			arcombine(cbi("firewall/rules"), cbi("firewall/rule-details")),
			_("Traffic Rules"), 30).leaf = true

		--entry({user, "network", "firewall", "custom"},
		--	cbi("firewall/custom"),
		--	_("Custom Rules"), 40).leaf = true
	end
end
