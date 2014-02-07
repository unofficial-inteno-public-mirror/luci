--[[
LuCI - Lua Configuration Interface

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--
local ds = require "luci.dispatcher"
local datatypes = require("luci.cbi.datatypes")
local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- Read line counts from driver
lineInfo = luci.sys.exec("/usr/bin/brcminfo")
lines = string.split(lineInfo, "\n")
line_nr = 0
if #lines == 5 then
	dectInfo = lines[1]
	dectCount = tonumber(dectInfo:match("%d+"))
	fxsInfo = lines[2]
	fxsCount = tonumber(fxsInfo:match("%d+"))
	allInfo = lines[4]
	allCount = tonumber(allInfo:match("%d"))
else
	dectCount = 0
	fxsCount = 0
	allCount = 0
end

-- Create a map and a section
m = Map("voice_pbx", "Tone Selection")
m.redirect = dsp.build_url("admin/services/voice/voice_ivr")
s = m:section(NamedSection, arg[1], "ivr")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_pbx", arg[1]) ~= "tone_selection" then
	luci.http.redirect(m.redirect)
	return
else
	local number = m:get(arg[1], "number")
	if not number or #number == 0 then
		m.title = "New Tone Selection"
	else
		m.title = "Edit Tone Selection"
	end
end

number = s:option(Value, "number", "Number", "Number to press to get connected")

-- Enabled checkbox
e = s:option(Flag, "enabled", "Enabled")
e.default = 0

user = s:option(ListValue, "user", "User", "User to get connected to. Can be either a SIP user, a physical line, a call queue or an other IVR")
lineCount = 0
m.uci:foreach("voice_pbx", "brcm_line",
	function(s1)
		if lineCount < allCount then
			user:value(s1['.name'], s1['name'])
		end
		lineCount = lineCount + 1
	end
)
m.uci:foreach("voice_pbx", "sip_user",
	function(s1)
		user:value(s1['.name'], s1['name'])
	end
)
m.uci:foreach("voice_pbx", "queue",
	function(s1)
		user:value(s1['.name'], s1['name'])
	end
)
m.uci:foreach("voice_pbx", "ivr",
	function(s1)
		user:value(s1['.name'], s1['name'])
	end
)

return m
