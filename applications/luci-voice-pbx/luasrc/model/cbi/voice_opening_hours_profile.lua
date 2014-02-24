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
m = Map("voice_pbx", "Opening Hours Profile")
m.redirect = dsp.build_url("admin/services/voice/voice_opening_hours")
s = m:section(NamedSection, arg[1], "opening_hours_profile")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_pbx", arg[1]) ~= "opening_hours_profile" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	if not name or #name == 0 then
		m.title = "New Opening Hours Profile"
	else
		m.title = "Edit Opening Hours Profile"
	end
end

s:option(Value, "name", "Name", "Display name")
invert = s:option(Flag, "invert", "Invert", "Specify timespans when closed.")
invert.default = 1

s = m:section(TypedSection, "timespan", "Timespans", "Specify as 00:00-23:59; mon-sun; 1-31; jan-dec.<br/> Use * as wildcard.")
function s.filter(self, section)
        owner = m.uci:get("voice_pbx", section, 'owner')
	if owner == arg[1] then
		return true
	end
        return false
end
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true

-- Find the lowest free section number
function get_new_section_number()
        local section_nr = 0
        while m.uci:get("voice_pbx", "timespan" .. section_nr) do
                section_nr = section_nr + 1
        end
        return section_nr
end

-- This function is called when a new tone selection should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s.create(self, section)
	section_number = get_new_section_number()
	data = { owner = arg[1] }
	newSelection = m.uci:section("voice_pbx", "timespan", "timespan" .. section_number , data)
end

-- Called when an account is being deleted
function s.remove(self, section)
        TypedSection.remove(self, section)
end

s:option(Value, "name", "Name")
s:option(Value, "time_range", "Time Range")
s:option(Value, "days_of_week", "Days of Week")
s:option(Value, "days_of_month", "Days of Month")
s:option(Value, "months", "Month")

return m
