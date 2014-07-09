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
local dsp = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice", "Conference Room")
m.redirect = dsp.build_url("admin/services/voice/conference")
s = m:section(NamedSection, arg[1], "conference_room")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice", arg[1]) ~= "conference_room" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	if not name or #name == 0 then
		m.title = "New Conference Room"
	else
		m.title = "Edit Conference Room"
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

id = s:option(Value, "id", "ID", "Conference room ID")
function id.validate(self, value, section)
	if not value:match("^%d+$") then
		return nil, "ID can only consist of digits 0-9"
	end
	return value
end

e = s:option(Flag, "enabled", "Enabled")

return m
