module("luci.controller.xdsl", package.seeall)

local guser = luci.dispatcher.context.path[1]

function index()
        local uci = require("luci.model.uci").cursor()
        local net = require "luci.model.xdsl".init(uci)
	local users = { "admin", "support", "user" }
        local page

	for k, user in pairs(users) do
		page = node(user, "status", "dslstats")
		page.target = template("admin_status/xdsl")
		page.title  = _("DSL Stats")
		page.subindex = true

		entry({user, "status", "dslstats", "xdsl"}, template("admin_status/xdsl"), "xDSL Statistics", 1)
		entry({user, "status", "dslstats", "xtm"}, template("admin_status/xtm"), "xTM Statistics", 2)

		page = node(user, "status", "berstart")
		page.target = template("admin_status/berstart")

		page = node(user, "status", "bershowresults")
		page.target = template("admin_status/bershowresults")

		page = entry({user, "network", "xtm_reset"}, call("xtm_reset"), nil)
		page.leaf = true

		page = entry({user, "network", "xdsl_reset"}, call("xdsl_reset"), nil)
		page.leaf = true

		page = entry({user, "network", "xdsl_berstart"}, call("xdsl_berstart"), nil)
		page.leaf = true

		page = entry({user, "network", "xdsl_berstop"}, call("xdsl_berstop"), nil)
		page.leaf = true

		page = entry({user, "network", "xdsl_bershow"}, call("xdsl_bershow"), nil)
		page.leaf = true
	end

end					

function xtm_reset() -- Call Reset xTM Statistics function
	local netmd = require "luci.model.xdsl".init()
	
	local net = netmd:reset_tm()
	if net then
		luci.http.redirect(luci.dispatcher.build_url("%s/status/dslstats/xtm" %guser))
		return
	end
end
								
function xdsl_reset() -- Call Reset xDSL Statistics function
	local netmd = require "luci.model.xdsl".init()
		
	local net = netmd:reset_dsl()
	if net then
		luci.http.redirect(luci.dispatcher.build_url("%s/status/dslstats/xdsl" %guser))
		return
	end
end
															
function xdsl_berstart(time) -- Call Start BER Test function
	local netmd = require "luci.model.xdsl".init()
																
	local net = netmd:berstart_dsl(time)
	if net then
		luci.http.redirect(luci.dispatcher.build_url("%s/status/bershowresults" %guser))
		return
	end
end
																							
function xdsl_berstop() -- Call Stop BER Test function
	local netmd = require "luci.model.xdsl".init()

	local net = netmd:berstop_dsl()
	if net then
		luci.http.redirect(luci.dispatcher.build_url("%s/status/bershowresults" %guser))
		return
	end
end
