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
m = Map("voice", "Mailbox")
m.redirect = dsp.build_url("admin/services/voice/voicemail")
s = m:section(NamedSection, arg[1], "mailbox")
s.anonymous = true
s.addremove = false

function user_has_mailbox(user)
	v = false
	m.uci.foreach("voice", "mailbox",
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
if m.uci:get("voice", arg[1]) ~= "mailbox" then
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
user = s:option(ListValue, "user", "User")
current_user = nil
if not create_new then
	current_user = m.uci:get("voice", arg[1], "user")
end
user:value("-", "-")
vc.foreach_user({'brcm', 'sip'},
	function(v)
		if not user_has_mailbox(v['.name']) or v['.name'] == current_user then
			user:value(v['.name'], v['name'])
		end
	end
)
m.uci:foreach("voice", "sip_service_provider",
	function(v)
		if not user_has_mailbox(v['.name']) or v['.name'] == current_user then
			user:value(v['.name'], v['name'])
		end
	end
)
function user.validate(self, value, section)
	ok = true
	m.uci:foreach("voice", "mailbox",
		function(s1)
			if s1['.name'] ~= section and s1['user'] ~= '-' and s1['user'] == value then
				ok = false
			end
		end
	)
	if not ok then
		return nil, "User already has a mailbox"
	end
	return value
end

pin = s:option(Value, "pin", "PIN", "Enter a new PIN code for accessing the mailbox.\
	If no value is entered the PIN code will remain unchanged.")
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
