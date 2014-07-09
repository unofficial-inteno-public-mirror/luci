--[[
LuCI - Lua Configuration Interface

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

local datatypes = require("luci.cbi.datatypes")
local dsp = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice", "Call Queue")
m.redirect = dsp.build_url("admin/services/voice/queues")
s = m:section(NamedSection, arg[1], "queue")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice", arg[1]) ~= "queue" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	if not name or #name == 0 then
		m.title = "New Call Queue"
	else
		m.title = "Edit Call Queue"
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

opening_hours = s:option(ListValue, "opening_hours_profile", "Opening Hours Profile")
opening_hours:value("-", "-")
m.uci:foreach("voice", "opening_hours_profile",
	function(v)
		opening_hours:value(v['.name'], v['name'])
	end
)

-- Enabled checkbox
e = s:option(Flag, "enabled", "Queue Enabled")
e.default = 0

-- Extension, must be unique (useful to transfer a call to the queue)
extension = s:option(Value, "extension", "Extension", "Extension to call this queue")
function extension.validate(self, value, section)
	return vc.validate_extension(value, section)
end
function extension.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Extension is mandatory")
	end	
end

-- Create dropdown to choose queue strategy
strategy = s:option(ListValue, "strategy", "Strategy")
strategy:value("ringall", "Ring all")
strategy:value("leastrecent", "Ring least recently hung up member first")
strategy:value("fewestcalls", "Ring the member with fewest calls first")
strategy:value("random", "Ring random")
strategy:value("rrmemory", "Round Robin")
strategy:value("linear", "Ring members in order specified")

-- Create and populate dropdowns with available queue members
members = s:option(MultiValue, "members", "Queue members")
lineCount = 0

vc.foreach_user({'brcm', 'sip'},
	function(v)
		members:value(v['.name'], v['name'])
	end
)

return m
