--[[
LuCI - Lua Configuration Interface - miniDLNA support

Copyright 2012 Gabor Juhos <juhosg@openwrt.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

module("luci.controller.minidlna", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/minidlna") then
		return
	end

	local users = { "admin", "support", "user" }
	local page

	for k, user in pairs(users) do
		page = entry({user, "services", "minidlna"}, cbi("minidlna"), _("miniDLNA"))
		page.dependent = true
		
		entry({user, "services", "minidlna", "minidlna_status"}, call("minidlna_status"))
	end
end

function minidlna_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local port = tonumber(uci:get_first("minidlna", "minidlna", "port"))

	local status = {
		running = (sys.call("pidof minidlna >/dev/null") == 0),
		audio   = 0,
		video   = 0,
		image   = 0
	}

	if status.running then
		local fd = sys.httpget("http://127.0.0.1:%d/" % (port or 8200), true)
		if fd then
			local html = fd:read("*a")
			if html then
				status.audio = (tonumber(html:match("Audio files: (%d+)")) or 0)
				status.video = (tonumber(html:match("Video files: (%d+)")) or 0)
				status.image = (tonumber(html:match("Image files: (%d+)")) or 0)
			end
			fd:close()
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
