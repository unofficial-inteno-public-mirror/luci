--[[
LuCI - Lua Configuration Interface

Copyright 2011 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: forward-details.lua 8962 2012-08-09 10:03:32Z jow $
]]--

local datatypes = require("luci.cbi.datatypes")
local vc = require "luci.model.cbi.voice.common"
local vrsc = require "luci.model.cbi.voice.ringing_schedule_common"
require "luci.util"

local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice_client", "Ringing Schedule")
m.redirect = dsp.build_url("admin/services/voice/ringing_schedule")
s = m:section(NamedSection, arg[1], "ringing_schedule")
s.anonymous = true
s.addremove = false

-- Redirect if we have nothing to edit or set page title if we do
if m.uci:get("voice_client", arg[1]) ~= "ringing_schedule" then
	luci.http.redirect(m.redirect)
	return
else
	m.title = "Edit Ringing Schedule"
end

-- Days                                                            
days = s:option(MultiValue, "days", "Days")
days:value('Monday')
days:value('Tuesday')
days:value('Wednesday')
days:value('Thursday')
days:value('Friday')
days:value('Saturday')
days:value('Sunday')
days.default = '' 

-- Time
time = s:option(Value, "time", "Time")
time.default = ""
function time.validate(self, value, section)
	return vrsc.validate_time(value)
end

-- SIP Account
sip_service_provider = s:option(ListValue, "sip_service_provider", "SIP Account")
m.uci:foreach("voice_client", "sip_service_provider",
	function(s1)
		if s1.enabled == "1" then
			sip_service_provider:value(s1['.name'], s1.name)
		end
	end)

return m
