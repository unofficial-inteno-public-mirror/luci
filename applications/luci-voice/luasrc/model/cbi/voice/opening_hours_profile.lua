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
m = Map("voice", "Opening Hours Profile")
m.redirect = dsp.build_url("admin/services/voice/opening_hours")
s = m:section(NamedSection, arg[1], "opening_hours_profile")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice", arg[1]) ~= "opening_hours_profile" then
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

name = s:option(Value, "name", "Name", "Display name")
function name.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Name is mandatory")
	end	
end

invert = s:option(Flag, "invert", "Invert", "Specify timespans when closed.")
invert.default = 1

s = m:section(TypedSection, "timespan", "Timespans", "Specify as 00:00-23:59; mon-sun; 1-31; jan-dec.<br/> Use * as wildcard.")
function s.filter(self, section)
        owner = m.uci:get("voice", section, 'owner')
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
        while m.uci:get("voice", "timespan" .. section_nr) do
                section_nr = section_nr + 1
        end
        return section_nr
end

-- This function is called when a new tone selection should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s.create(self, section)
	section_number = get_new_section_number()
	data = { owner = arg[1], time_range = "*", days_of_week = "*", days_of_month = "*", months = "*" }
	newSelection = m.uci:section("voice", "timespan", "timespan" .. section_number , data)
end

-- Called when an account is being deleted
function s.remove(self, section)
        TypedSection.remove(self, section)
end

s:option(Value, "name", "Name")

tr = s:option(Value, "time_range", "Time Range")
function tr.validate(self, value, section)
	if value == "*" then
		return value
	end

	if not value:match("^[0-9][0-9]:[0-9][0-9]%-[0-9][0-9]:[0-9][0-9]$") then
		return nil, "Invalid time range format"
	end
	return value
end
function tr.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Time Range is mandatory")
	end	
end

dow = s:option(Value, "days_of_week", "Days of Week")
function dow.validate(self, value, section)
	if value == "*" then
		return value
	end

	local days = { "mon", "tue", "wed", "thu", "fri", "sat", "sun" }
	if value:match("^[a-z][a-z][a-z]%-[a-z][a-z][a-z]$") then
		for d in string.gmatch(value, "%l+") do
			valid_day = false
			for _,v in pairs(days) do
				if v == d then
					valid_day = true
					break
				end
			end
			if not valid_day then
				return nil, "Invalid day " .. d
			end
		end
	else
		return nil, "Invalid days of week format"
	end
	return value
end
function dow.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Days of Week is mandatory")
	end	
end

dom = s:option(Value, "days_of_month", "Days of Month")
function dom.validate(self, value, section)
	if value == "*" then
		return value
	end

	if not value:match("^[0-9][0-9]?%-[0-9][0-9]?$") then
		return nil, "Invalid days of month format"
	end
	for d in string.gmatch(value, "%d+") do
		num = tonumber(d)
		if num < 1 or num > 31 then
			return nil, "Invalid day of month " .. d
		end
	end
	return value
end
function dom.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Days of Month is mandatory")
	end	
end

mon = s:option(Value, "months", "Months")
function mon.validate(self, value, section)
	if value == "*" then
		return value
	end

	local months = { "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec" }
	if value:match("^[a-z][a-z][a-z]%-[a-z][a-z][a-z]$") then
		for m in string.gmatch(value, "%l+") do
			valid_month = false
			for _,v in pairs(months) do
				if v == m then
					valid_month = true
					break
				end
			end
			if not valid_month then
				return nil, "Invalid month " .. m
			end
		end
	else
		return nil, "Invalid months format"
	end
	return value
end
function mon.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Months is mandatory")
	end	
end

return m
