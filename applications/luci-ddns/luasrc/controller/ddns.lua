--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ddns.lua 9507 2012-11-26 12:53:43Z jow $
]]--

module("luci.controller.ddns", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ddns") then
		return
	end
	
	local users = { "admin", "support", "user" }
	local page

	for k, user in pairs(users) do
		page = entry({user, "services", "ddns"}, cbi("ddns/ddns"), _("Dynamic DNS"), 60)
		page.dependent = true
	end

	page = entry({"mini", "network", "ddns"}, cbi("ddns/ddns", {autoapply=true}), _("Dynamic DNS"), 60)
	page.dependent = true
end
