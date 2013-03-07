module("luci.controller.support.firewall", package.seeall)

function index()
	entry({"support", "network", "firewall"},
		alias("support", "network", "firewall", "zones"),
		_("Firewall"), 60)

	entry({"support", "network", "firewall", "zones"},
		arcombine(cbi("firewall/zones"), cbi("firewall/zone-details")),
		_("General Settings"), 10).leaf = true

	entry({"support", "network", "firewall", "forwards"},
		arcombine(cbi("firewall/forwards"), cbi("firewall/forward-details")),
		_("Port Forwards"), 20).leaf = true

	entry({"support", "network", "firewall", "rules"},
		arcombine(cbi("firewall/rules"), cbi("firewall/rule-details")),
		_("Traffic Rules"), 30).leaf = true

	entry({"support", "network", "firewall", "custom"},
		cbi("firewall/custom"),
		_("Custom Rules"), 40).leaf = true
end
