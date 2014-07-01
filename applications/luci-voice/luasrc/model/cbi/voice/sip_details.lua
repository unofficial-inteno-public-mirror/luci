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
local vc = require "luci.model.cbi.voice.common"


local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice", "SIP Account")
m.redirect = dsp.build_url("admin/services/voice/sip")
s = m:section(NamedSection, arg[1], "sip_service_provider")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice", arg[1]) ~= "sip_service_provider" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "name")
	if not name or #name == 0 then
		name = "Unknown SIP Account"
	end
	m.title = name
end

-- Change sip_account setting for lines using a disabled account
-- For new and disabled accounts that are being enabled,
-- ensure that user has supplied a password
old_enabled_val = m.uci:get_bool("voice", s.section, "enabled")
function parse_enabled(self, section)                                                                                                                           
	Flag.parse(self, section)
	local fvalue = self:formvalue(section)

	if not fvalue then
		vc.foreach_user({'brcm', 'sip'},
			function(v)
				name = v['.name']
				if v.sip_account == section then
					m.uci:set("voice", name, "sip_account", "-")
				end
			end
		)
	end

	local passwd = pwd:formvalue(section)
	if fvalue and not old_enabled_val then
		if not passwd or #passwd == 0 then
			self.add_error(self, section, "missing", "Please enter a password")
		end
	end
end

-- Enabled checkbox
e = s:option(Flag, "enabled", "Account Enabled")
e.default = 0
e.parse = parse_enabled

target = s:option(ListValue, "target", "Incoming calls to")
target:value('direct', 'Direct')
if vc.has_package("luci-app-voice-queues") then
	target:value('queue', 'Queue')
end
if vc.has_package("luci-app-voice-ivr") then
	target:value('ivr', 'IVR')
end
target.default = 'direct'

-- Create a set of checkboxes for lines to call
lines = s:option(MultiValue, "call_lines", "&nbsp;")
lines:depends('target', 'direct')
line_nr = 0
-- DECT
for i = 1, dectCount do
	lines:value("BRCM/" .. line_nr, "DECT " .. i)
	line_nr = line_nr + 1
end
-- FXS
for i = 1, fxsCount do
	lines:value("BRCM/" .. line_nr, "Tel " .. i)
	line_nr = line_nr + 1
end
-- SIP users
vc.foreach_user({'sip'},
        function(v)
                lines:value("SIP/" .. v['user'], v['name'])
        end
)

if vc.has_package("luci-app-voice-queues") then
	queue = s:option(ListValue, "call_queue", "&nbsp;")
	queue:depends('target', 'queue')
	m.uci:foreach("voice", "queue",
		function(v)
			queue:value(v['.name'], v['name'])
		end
	)
end

if vc.has_package("luci-app-voice-ivr") then
	ivr = s:option(ListValue, "call_ivr", "&nbsp;")
	ivr:depends('target', 'ivr')
	m.uci:foreach("voice", "ivr",
		function(v)
			ivr:value(v['.name'], v['name'])
		end
	)
end

if vc.has_package("luci-app-voice-call-filters") then
	call_filter = s:option(ListValue, "call_filter", "Call filter")
	call_filter:value("-", "-")
	m.uci:foreach("voice", "call_filter",
		function(s1)
			call_filter:value(s1[".name"], s1["name"])
		end
	)
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

ptimes = {
	ulaw = {min = 10, max = 150, default = 20, increment = 10},
	alaw = {min = 10, max = 150, default = 20, increment = 10},
	g729 = {min = 10, max = 230, default = 20, increment = 10},
	g723 = {min = 30, max = 300, default = 30, increment = 30},
	g726 = {min = 10, max = 300, default = 20, increment = 10}
}

for a, b in pairs(codecs) do
	ptime = s:option(ListValue, "ptime_"..a, b.." packetization")
	min = ptimes[a]["min"]
	max = ptimes[a]["max"]
	inc = ptimes[a]["increment"]
	def = ptimes[a]["default"]
	for period = min,max,inc do
		ptime:value(period, period.." ms")
	end

	i = 0
	for k, v in pairs(codecs) do
		ptime:depends("codec"..i, a)
		i = i + 1
	end

	ptime.default = def
end

autoframing = s:option(Flag, "autoframing", "Autoframing", "Negotiate packetization at call establishment")

transports = {udp = "UDP", tcp = "TCP", tls = "TLS"}
transport = s:option(ListValue, 'transport', "SIP Transport")
transport.default = "udp"
for k, v in pairs(transports) do
	transport:value(k, v)
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
