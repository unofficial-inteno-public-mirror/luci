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
m = Map("voice_client", "Mailbox")
m.redirect = dsp.build_url("admin/services/voice/voicemail")
s = m:section(NamedSection, arg[1], "mailbox")
s.anonymous = true
s.addremove = false

function user_has_mailbox(user)
	v = false
	m.uci.foreach("voice_client", "mailbox",
		function(s1)
			if s1['user'] == user then
				v = true
			end
		end
	)
	return v
end

create_new = false
-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_client", arg[1]) ~= "mailbox" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "user")
	create_new = not name or #name == 0
	if create_new then
		m.title = "New Mailbox"
	else
		m.title = "Edit Mailbox"
	end
end

-- Create and populate dropdown with available users
name = s:option(Value, "name", "Name")

boxnumber = s:option(Value, "boxnumber", "Boxnumber", "Used as login when accessing the mailbox")
function boxnumber.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Boxnumber is mandatory")
	end     
end
function boxnumber.validate(self, value, section)
	ok = true
	m.uci:foreach("voice_client", "mailbox",
		function(v)
			if v['.name'] ~= section and v['boxnumber'] == value then
				ok = false
			end
		end
	)
	if not ok then
		return nil, "Boxnumber already used by another mailbox"
	end
	return value
end

pin = s:option(Value, "pin", "PIN", "Enter a new PIN code for accessing the mailbox.\
	If no value is entered the PIN code will remain unchanged")
pin.password = false
pin.rmempty = true
function pin.validate(self, value, section)
	if not value:match("^[0-9][0-9][0-9][0-9]$") then
		return nil, "PIN code must be exactly 4 digits"
	end
	return value
end

-- Never read the PIN code from our configuration file
function pin.cfgvalue(self, section)
	return "" 
end

-- Enabled checkbox
e = s:option(Flag, "enabled", "Enabled")
e.default = 0
e.parse = parse_enabled

return m
