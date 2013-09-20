
module("luci.controller.support.bwtest", package.seeall)

function index()

	local uci = require("luci.model.uci").cursor()
	local net = require "luci.model.bwtest".init(uci)

	local page
	
	if nixio.fs.access("/usr/sbin/tptest") then
		page = node("support", "network", "spstart")
		page.target = template("admin_network/spstart")
		page.title  = _("Speed Test")
	end

	page = node("support", "network", "spshowresults")
	page.target = template("admin_network/spshowresults")

	page = entry({"support", "network", "bwidth_spstart"}, call("bwidth_spstart"), nil)
	page.leaf = true

end

function bwidth_spstart(opts) -- Call Start Speed Test function
	local netmd = require "luci.model.bwtest".init()
	
	local net = netmd:startspt(opts)
	if net then
		luci.http.redirect(luci.dispatcher.build_url("support/network/spshowresults"))
		return
	end
end

