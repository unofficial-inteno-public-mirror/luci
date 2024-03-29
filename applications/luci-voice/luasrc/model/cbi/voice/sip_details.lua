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
require "luci.util"


local dsp = require "luci.dispatcher"

arg[1] = arg[1] or ""

-- Create a map and a section
m = Map("voice_client", "SIP Account")
m.redirect = dsp.build_url("admin/services/voice/sip")
s = m:section(NamedSection, arg[1], "sip_service_provider")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_client", arg[1]) ~= "sip_service_provider" then
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
old_enabled_val = m.uci:get_bool("voice_client", s.section, "enabled")
function parse_enabled(self, section)                                                                                                                           
	Flag.parse(self, section)
	local fvalue = self:formvalue(section)

	if not fvalue then
		vc.foreach_user({'brcm', 'sip'},
			function(v)
				name = v['.name']
				if v.sip_account == section then
					m.uci:set("voice_client", name, "sip_account", "-")
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
	
	if fvalue and section == "sip0" then
		vc.foreach_user({'brcm', 'sip'},
			function(v)
				if v['sip_account'] == "-" then
					m.uci:set("voice_client", v['.name'], "sip_account", section)
				end
			end
		)
	end
end

-- Enabled checkbox
e = s:option(Flag, "enabled", "Account Enabled")
e.default = 0
e.parse = parse_enabled

target = s:option(ListValue, "target", "Incoming calls to")
target:value('direct', 'Direct')
target.default = 'direct'

-- Create a set of checkboxes for lines to call
lines = s:option(MultiValue, "call_lines", "&nbsp;")

-- Backwards compatibility
-- Add 'BRCM/' prefix to lines with no prefix
function lines.cfgvalue(self, section)
	value = Value.cfgvalue(self, section)	
	if not value then
		return nil
	end
	lines = {}
	for k,v in pairs(luci.util.split(value, " ")) do
		if tonumber(v) ~= nil then
			table.insert(lines, "BRCM/" .. v)
		else
			table.insert(lines, v)
		end
	end
	return table.concat(lines, " ")
end

lines:depends('target', 'direct')
line_nr = 0
-- DECT
for i = 1, dectCount do
	linenum = "brcm%d" %line_nr
	lines:value("BRCM/" .. line_nr, m.uci:get("voice_client", linenum, "name") or linenum:upper())
	line_nr = line_nr + 1
end
-- FXS
for i = 1, fxsCount do
	linenum = "brcm%d" %line_nr
	lines:value("BRCM/" .. line_nr, m.uci:get("voice_client", linenum, "name") or linenum:upper())
	line_nr = line_nr + 1
end
-- SIP users
vc.foreach_user({'sip'},
        function(v)
		if v['user'] then
	                lines:value("SIP/" .. v['user'], v['name'])
		end
        end
)

mailbox = s:option(ListValue, "mailbox", "Mailbox", "")
m.uci:foreach("voice_client", "mailbox",
	function(s1)
		mailbox:value(s1[".name"], s1["name"])
	end
)	
mailbox:value("-", "-")
mailbox.default = "-"
mailbox:depends('target', 'direct')

if vc.has_package("luci-app-voice-pbx") then
	queue = s:option(ListValue, "call_queue", "&nbsp;")
	queue:depends('target', 'queue')

	num = 0
	m.uci:foreach("voice_client", "queue",
		function(v)
			queue:value(v['.name'], v['name'])
			num = num + 1
		end
	)
	if num ~= 0 then
		target:value('queue', 'Queue')
	end

	ivr = s:option(ListValue, "call_ivr", "&nbsp;")
	ivr:depends('target', 'ivr')

	num = 0
	m.uci:foreach("voice_client", "ivr",
		function(v)
			ivr:value(v['.name'], v['name'])
			num = num + 1
		end
	)
	if num ~= 0 then
		target:value('ivr', 'IVR')
	end	
end

call_filter = s:option(ListValue, "call_filter", "Call Filter")
call_filter:value("-", "-")
m.uci:foreach("voice_client", "call_filter",
	function(s1)
		call_filter:value(s1[".name"], s1["name"])
	end
)

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
codecs = {}
ptimes = {}
i = 0
m.uci:foreach("voice_codecs", "supported_codec",
	function(s1)
		codecs[s1['.name']] = s1.name;
		pmin = tonumber(s1.ptime_min) or 10
		pmax = tonumber(s1.ptime_max) or 300
		pdef = tonumber(s1.ptime_default) or 20
		pinc = tonumber(s1.ptime_increment) or 10
		ptimes[s1['.name']] = { min = pmin, max = pmax, default = pdef, increment = pinc }
	end)

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

encryption = s:option(Flag, 'encryption', "Encryption", "Use Secure Real-time Transport Protocol (SRTP)")
encryption.default = 0
encryption.rmempty = false
encryption:depends('transport', 'tls')

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
