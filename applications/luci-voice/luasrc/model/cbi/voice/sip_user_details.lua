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
m = Map("voice_client", "SIP User")
m.redirect = dsp.build_url("admin/services/voice/sip_users")
s = m:section(NamedSection, arg[1], "sip_user")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_client", arg[1]) ~= "sip_user" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	if not name or #name == 0 then
		m.title = "New SIP User"
	else
		m.title = "Edit SIP User"
	end
end


-- Enabled checkbox
e = s:option(Flag, "enabled", "Account Enabled")
e.default = 0
e.parse = parse_enabled

name = s:option(Value, "name", "Name", "Display name used in Caller Id")
function name.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Name is mandatory")
	end	
end

-- Extension, must be unique
extension = s:option(Value, "extension", "Extension", "Extension for this user")
function extension.validate(self, value, section)
	return vc.validate_extension(value, arg[1])
end
function extension.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "Extension is mandatory")
	end	
end

-- Create a set of checkboxes for lines to call
user = s:option(Value, "user", "Username", "The User id for the account (defaultuser)")
function user.parse(self, section)
	Value.parse(self, section)
	local value = self:formvalue(section)
	if not value or #value == 0 then
		self.add_error(self, section, "missing", "User is mandatory")
	end	
end

pwd = s:option(Value, "secret", "Password",
	"When your password is saved, it disappears from this field and is not displayed\
	for your protection. The previously saved password will be changed only when you\
	enter a value different from the saved one.")
pwd.password = true
pwd.rmempty = false

-- We skip reading off the saved value and return nothing.
function pwd.cfgvalue(self, section)
    return "" 
end

-- Write/change password only if user has entered a value
function pwd.write(self, section, value)
	if value and #value > 0 then
		Value.write(self, section, value);
	end
end

-- Create and populate dropdown with available sip provider choices
sip_provider = s:option(ListValue, "sip_provider", "Call out using SIP provider")
m.uci:foreach("voice_client", "sip_service_provider",
	function(s1)
		if s1.enabled == "1" then
			sip_provider:value(s1['.name'], s1.name)
		end
	end)
sip_provider:value("-", "-")
sip_provider.default = "-"

mailbox = s:option(ListValue, "mailbox", "Mailbox")
m.uci:foreach("voice_client", "mailbox",
	function(s1)
		mailbox:value(s1[".name"], s1["name"])
	end
)
mailbox:value("-", "-")
mailbox.default = "-"

-- Create and populate dropdowns with available codec choices                            
codecs = {ulaw = "G.711MuLaw", alaw = "G.711ALaw", g729 = "G.729a", g723 = "G.723.1", g726 = "G.726_32", g722 = "G.722", gsm = "GSM", ilbc = "iLBC"}
i = 0
for a, b in pairs(codecs) do
	if i == 0 then
		codec = s:option(ListValue, "codec"..i, "Preferred codecs")
		codec.default = "alaw"
	else
		codec = s:option(ListValue, "codec"..i, "&nbsp;")
		codec.default = "-"
		for k, v in pairs(codecs) do
			codec:depends("codec"..i-1, k)
		end
	end
	for k, v in pairs(codecs) do
		codec:value(k, v)
	end
	codec:value("-", "-")
	i = i + 1
end

h = s:option(Value, "host", "Host", "Host for this user (leave empty for dynamic)")
h.rmempty = true
h.optional = true
function h.validate(self, value, section)
	if datatypes.host(value) then
		return value
	end
	return nil, "Host must be a valid hostname or ip address"
end

qualify = s:option(Value, "qualify", "Qualify", "Check that user is reachable")
qualify.rmempty = true
qualify.optional = true

return m
