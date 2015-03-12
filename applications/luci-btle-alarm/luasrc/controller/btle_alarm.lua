module("luci.controller.btle_alarm", package.seeall)

function index()
	entry({"admin", "services", "btle_alarm"}, cbi("btle_alarm"), "Pair Bluetooth", 99)
end
