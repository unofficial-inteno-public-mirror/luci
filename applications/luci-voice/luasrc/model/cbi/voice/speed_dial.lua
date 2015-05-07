--[[
LuCI - Lua Configuration Interface

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

-- http://luci.subsignal.org/trac/browser/luci/trunk/applications/luci-radvd/luasrc/model/cbi/radvd.lua?rev=6
local ds = require "luci.dispatcher"
local datatypes = require "luci.cbi.datatypes"

m = Map("voice_client", "Speed Dial")

speed = m:section(TypedSection, "speed_dial", "Speed Dial")
speed.template = "cbi/tblsection"
speed.anonymous = true
speed.addremove = true

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_client", "speed_dial" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- Find lowest unused tone number
function get_lowest_free_tone()
	local tones = {}
	m.uci:foreach("voice_client", "speed_dial",
		function(v)
			tones[v['tone']] = true
		end
	)
	
	for i=0,9 do
		if tones[tostring(i)] == nil then
			return i
		end
	end
	
	return nil
end

-- This function is called when a new tone selection should be configured i.e. when
-- user presses the "Add" button.
function speed.create(self, section)
	section_number = get_new_section_number()
	tone = get_lowest_free_tone()
	
	if tone ~= nil then
		data = { tone = tone }
		m.uci:section("voice_client", "speed_dial", "speed_dial" .. section_number , data)	
	end
end
	
tone = speed:option(Value, "tone", "Tone")

function tone.validate(self, value, section)
	if not value:match("^[0-9]$") then
		return nil, "Invalid tone " .. value
	end
	
	already_used = false
	m.uci:foreach("voice_client", "speed_dial",
		function(v)
			if v['.name'] ~= section and v['tone'] == value then
				already_used = true
			end
		end
	)
	
	if already_used then
		return nil, "Number already defined for speed dial " .. value
	end
	
	return value
end

number = speed:option(Value, "number", "Number")

function number.validate(self, value, section)
	if not datatypes.phonedigit(value) then
		return nil, value .. " is not a valid phone number"
	end
	
	-- Must be longer than 1 digit
	if value:len() <= 1 then
		return nil, "Number must be at least two digits long"
	end
	
	return value
end

function number.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Number is mandatory")
	end
end

return m
