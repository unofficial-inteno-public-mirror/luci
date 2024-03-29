--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: index.lua 7789 2011-10-26 03:04:18Z jow $
]]--

module("luci.controller.admin.index", package.seeall)

function index()
	local root = node()
	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do
		if not root.target then
			root.target = alias(user)
			root.index = true
		end

		local page   = node(user)
		page.target  = firstchild()
		page.order   = 10
		page.sysauth = user
		page.sysauth_authenticator = "htmlauth"
		page.ucidata = true
		page.index = true

		-- Empty services menu to be populated by addons
		entry({user, "services"}, firstchild(), _("Services"), 40).index = true

		entry({user, "logout"}, call("action_logout"), _("Logout"), 90)
	end
end

function action_logout()
	local dsp = require "luci.dispatcher"
	local sauth = require "luci.sauth"
	if dsp.context.authsession then
		sauth.kill(dsp.context.authsession)
		dsp.context.urltoken.stok = nil
	end

	luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
	luci.http.redirect(luci.dispatcher.build_url())
end
