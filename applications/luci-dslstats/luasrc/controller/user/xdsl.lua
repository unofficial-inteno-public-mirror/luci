module("luci.controller.user.xdsl", package.seeall)

function index()

        local uci = require("luci.model.uci").cursor()
        local net = require "luci.model.xdsl".init(uci)
                
        local page

        page = node("user", "status", "xtm")
        page.target = template("admin_status/xtm")
        page.title  = _("xTM Statistics")

        page = node("user", "status", "xdsl")
        page.target = template("admin_status/xdsl")
        page.title  = _("xDSL Statistics")

        page = node("user", "status", "berstart")
        page.target = template("admin_status/berstart")

        page = node("user", "status", "bershowresults")
        page.target = template("admin_status/bershowresults")

        page = entry({"user", "network", "xtm_reset"}, call("xtm_reset"), nil)
        page.leaf = true

        page = entry({"user", "network", "xdsl_reset"}, call("xdsl_reset"), nil)
        page.leaf = true

        page = entry({"user", "network", "xdsl_berstart"}, call("xdsl_berstart"), nil)
        page.leaf = true

        page = entry({"user", "network", "xdsl_berstop"}, call("xdsl_berstop"), nil)
        page.leaf = true

        page = entry({"user", "network", "xdsl_bershow"}, call("xdsl_bershow"), nil)
        page.leaf = true

end					

function xtm_reset() -- Call Reset xTM Statistics function
	local netmd = require "luci.model.xdsl".init()
	
	local net = netmd:reset_tm()
	if net then
		luci.http.redirect(luci.dispatcher.build_url("user/status/xtm"))
		return
	end
end
								
function xdsl_reset() -- Call Reset xDSL Statistics function
	local netmd = require "luci.model.xdsl".init()
		
	local net = netmd:reset_dsl()
	if net then
		luci.http.redirect(luci.dispatcher.build_url("user/status/xdsl"))
		return
	end
end
															
function xdsl_berstart(time) -- Call Start BER Test function
	local netmd = require "luci.model.xdsl".init()
																
	local net = netmd:berstart_dsl(time)
	if net then
		luci.http.redirect(luci.dispatcher.build_url("user/status/bershowresults"))
		return
	end
end
																							
function xdsl_berstop() -- Call Stop BER Test function
	local netmd = require "luci.model.xdsl".init()

	local net = netmd:berstop_dsl()
	if net then
		luci.http.redirect(luci.dispatcher.build_url("user/status/bershowresults"))
		return
	end
end
