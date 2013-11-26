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

-- Check line counts
lineInfo = luci.sys.exec("/usr/bin/brcminfo")
lines = string.split(lineInfo, "\n")
if #lines == 5 then
	dectInfo = lines[1]
	dectCount = tonumber(dectInfo:match("%d+"))
	fxsInfo = lines[2]
	fxsCount = tonumber(fxsInfo:match("%d+"))
	allInfo = lines[4]
	allCount = tonumber(allInfo:match("%d+"))
else
	dectCount = 0
	fxsCount = 0
	allCount = 0
end


-- Parse function for enabled Flags, change sip_account setting for lines using a disabled account
function parse_enabled(self, section)
	Flag.parse(self, section)
	local fvalue = self:formvalue(section)

	if not fvalue then
		m.uci:foreach("voice_pbx", "brcm_line",
			function(s1)
				line_name = s1['.name']
				if s1.sip_account == section then
					m.uci:set("voice_pbx", line_name, "sip_account", "-")
				end
			end
		)

		m.uci:foreach("voice_pbx", "sip_user",
			function(s1)
				user_name = s1['.name']
				if s1.sip_account == section then
					m.uci:set("voice_pbx", user_name, "sip_account", "-")
				end
			end
		)
	end
end

local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice_pbx", "SIP Account")
m.redirect = dsp.build_url("admin/services/voice/voice_sip")
s = m:section(NamedSection, arg[1], "sip_service_provider")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_pbx", arg[1]) ~= "sip_service_provider" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	if not name or #name == 0 then
		name = "Unknown SIP Account"
	end
	m.title = name
end

-- Enabled checkbox
e = s:option(Flag, "enabled", "Account Enabled")
e.default = 0
e.parse = parse_enabled

-- Create a set of checkboxes for lines to call
lines = s:option(MultiValue, "call_lines", "Incoming calls to")
line_nr = 0
-- DECT
for i = 1, dectCount do
	lines:value(line_nr, "DECT " .. i)
	line_nr = line_nr + 1
end
-- FXS
for i = 1, fxsCount do
	lines:value(line_nr, "Tel " .. i)
	line_nr = line_nr + 1
end

domain = s:option(Value, 'domain', 'SIP domain name')
function domain.validate(self, value, section)
	if datatypes.host(value) then
		return value
	end
	return nil, "SIP domain name must be a hostname or ip address"
end

user = s:option(Value, "user", "Username", "The User id for the account, may be a phone number")

s:option(Value, "authuser", "Authentication Name", "Used in combination with password to register against SIP server")

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

s:option(Value, "displayname", "Display Name", "Display name used in Caller Id")

-- Create and populate dropdowns with available codec choices                            
codecs = {ulaw = "G.711MuLaw", alaw = "G.711ALaw", g729 = "G.729a", g723 = "G.723.1", g726 = "G.726_32"}
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

fax = s:option(Flag, "is_fax", "Use as Fax", "Indicate that this SIP account will be used for a fax machine. This will force some settings to enable inband fax.")
fax.default = 0

h = s:option(Value, "host", "SIP Server/Registrar", "Optional")
h.rmempty = true
function h.validate(self, value, section)
	if datatypes.host(value) then
		return value
	end
	return nil, "SIP Server/Registrar must be a hostname or ip address"
end

rport = s:option(Value, 'port', "SIP Server/Registrar Port", "Optional")
rport.rmempty = true
function rport.validate(self, value, section)
	if datatypes.port(value) then
		return value
	end
	return nil, "SIP Server/Registrar Port is invalid"
end

op = s:option(Value, "outboundproxy", "SIP Outbound Proxy", "Optional")
op.rmempty = true
function op.validate(self, value, section)
	if datatypes.host(value) then
		return value
	end
	return nil, "SIP Outbound Proxy must be a hostname or ip address"
end

opport = s:option(Value, 'outboundproxyport', "SIP Outbound Proxy Port", "Optional")
opport.rmempty = true
function opport.validate(self, value, section)
	if datatypes.port(value) then
		return value
	end
	return nil, "SIP Outbound Proxy Port is invalid"
end

return m
