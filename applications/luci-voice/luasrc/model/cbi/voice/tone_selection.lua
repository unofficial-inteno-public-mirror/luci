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
local vc = require "luci.model.cbi.voice.common"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice", "Tone Selection")
owner = m.uci:get("voice", arg[1], "owner") or ""
m.redirect = dsp.build_url("admin/services/voice/ivr/" .. owner)
s = m:section(NamedSection, arg[1], "ivr")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice", arg[1]) ~= "tone_selection" then
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
function number.validate(self, value, section)
	if not value:match("^[0-9]$") then
		return nil, "Number must be exactly 1 decimal digit"
	end
	return value
end

-- Enabled checkbox
e = s:option(Flag, "enabled", "Enabled")
e.default = 0

user = s:option(ListValue, "user", "User", "User to get connected to. Can be either a SIP user, a physical line, a call queue or an other IVR")
lineCount = 0

vc.foreach_user({'brcm', 'sip', 'queue', 'ivr'},
	function(v)
		user:value(v['.name'], v['name'])
	end
)

return m
