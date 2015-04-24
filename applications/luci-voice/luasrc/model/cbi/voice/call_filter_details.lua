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
m = Map("voice_client", "Call Filter")
m.redirect = dsp.build_url("admin/services/voice/call_filters")
s = m:section(NamedSection, arg[1], "call_filter")
s.anonymous = true
s.addremove = false

-- Find the lowest free section number
function get_new_section_number(direction)
        local section_nr = 0
        while m.uci:get("voice_client", "call_filter_rule_" .. direction .. section_nr) do
                section_nr = section_nr + 1
        end
        return section_nr
end

-- Set page title, or redirect if we have nothing to edit
create_new = false
if m.uci:get("voice_client", arg[1]) ~= "call_filter" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	create_new = not name or #name == 0
	if create_new then
		m.title = "New Call Filter"
	else
		m.title = "Edit Call Filter"
	end
end

name = s:option(Value, "name", "Name")
function name.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Name is mandatory")
	end	
end

outgoing = m:section(TypedSection, "call_filter_rule_outgoing", "Outgoing Calls", "Specify rules for outgoing calls. Use # to match a range of numbers. 123# will block calls to all numbers starting with 123.")
function outgoing.filter(self, section)
        owner = m.uci:get("voice_client", section, 'owner')
	if owner == arg[1] then
		return true
	end
        return false
end
outgoing.template = "cbi/tblsection"
outgoing.anonymous = true
outgoing.addremove = true

-- This function is called when a new call filter rule should be configured i.e. when
-- user presses the "Add" button.
function outgoing.create(self, section)
	if m.save == false then
		return
	end
	section_number = get_new_section_number("outgoing")
	data = { owner = arg[1], enabled = 1 }
	newSelection = m.uci:section("voice_client", "call_filter_rule_outgoing", "call_filter_rule_outgoing" .. section_number , data)
end

exten = outgoing:option(Value, "extension", "Called Number")
function exten.validate(self, value, section)
	if not value:match("^[0-9]+#?$") then
		return nil, value .. " is not a valid pattern"
        end
	return value
end
function exten.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Called number is mandatory")
	end	
end

enabled = outgoing:option(Flag, "enabled", "Enabled")
enabled.default = 1

s = m:section(NamedSection, arg[1], "call_filter")
s.anonymous = true

block_foreign = s:option(Flag, "block_foreign", "Block Foreign", "Block all outgoing calls to foreign numbers")
block_foreign.default = 0

block_special_rate = s:option(Flag, "block_special_rate", "Block Special Rate", "Block all outgoing calls to special rate numbers")
block_special_rate = 0

incoming = m:section(TypedSection, "call_filter_rule_incoming", "Incoming Calls", "Specify rules for incoming calls. Use # to match a range of numbers. 123# will block calls from all numbers starting with 123.")
function incoming.filter(self, section)
        owner = m.uci:get("voice_client", section, 'owner')
	if owner == arg[1] then
		return true
	end
        return false
end
incoming.template = "cbi/tblsection"
incoming.anonymous = true
incoming.addremove = true

-- This function is called when a new call filter rule should be configured i.e. when
-- user presses the "Add" button.
function incoming.create(self, section)
	if m.save == false then
		return
	end
	section_number = get_new_section_number("incoming")
	data = { owner = arg[1], enabled = 1 }
	newSelection = m.uci:section("voice_client", "call_filter_rule_incoming", "call_filter_rule_incoming" .. section_number , data)
end

exten = incoming:option(Value, "extension", "Calling Number")
function exten.validate(self, value, section)
	if not value:match("^[0-9]+#?$") then
		return nil, value .. " is not a valid pattern"
        end
	return value
end
function exten.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Calling number is mandatory")
	end	
end

enabled = incoming:option(Flag, "enabled", "Enabled")
enabled.default = 1

return m
