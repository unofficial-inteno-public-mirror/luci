--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: filebrowser.lua 3555 2008-10-10 21:52:22Z jow $
]]--

module("luci.controller.admin.filebrowser", package.seeall)

function index()
	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do
		entry( {user, "filebrowser"}, template("cbi/filebrowser") ).leaf = true
	end
end
