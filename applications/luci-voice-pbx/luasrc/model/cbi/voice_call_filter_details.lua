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
m = Map("voice_pbx", "Call Filter")
m.redirect = dsp.build_url("admin/services/voice/voice_call_filters")
s = m:section(NamedSection, arg[1], "call_filter")
s.anonymous = true
s.addremove = false

function num_call_filters(sip_provider)
	count = 0
	m.uci.foreach("voice_pbx", "call_filter",
		function(s1)
			if s1['sip_provider'] == sip_provider then
				count = count + 1
			end
		end
	)
	return count
end

-- Set page title, or redirect if we have nothing to edit
create_new = false
if m.uci:get("voice_pbx", arg[1]) ~= "call_filter" then
	luci.http.redirect(m.redirect)
	return
else
	local name = m:get(arg[1], "sip_provider")
	create_new = not name or #name == 0
	if create_new then
		m.title = "New Call Filter"
	else
		m.title = "Edit Call Filter"
	end
end

name = s:option(Value, "name", "Name")

s:option(Flag, "enabled", "Enabled")

incoming = s:option(ListValue, "incoming", "Incoming")
incoming:value("blacklist", "Blacklist")
incoming:value("whitelist", "Whitelist")
incoming.default = "blacklist"

outgoing = s:option(ListValue, "outgoing", "Outgoing")
outgoing:value("blacklist", "Blacklist")
outgoing:value("whitelist", "Whitelist")
outgoing.default = "blacklist"

s = m:section(TypedSection, "call_filter_rule", "Rules")
function s.filter(self, section)
        owner = m.uci:get("voice_pbx", section, 'owner')
	if owner == arg[1] then
		return true
	end
        return false
end
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true

-- Find the lowest free section number
function get_new_section_number()
        local section_nr = 0
        while m.uci:get("voice_pbx", "call_filter_rule" .. section_nr) do
                section_nr = section_nr + 1
        end
        return section_nr
end

-- This function is called when a new call filter rule should be configured i.e. when
-- user presses the "Add" button.
function s.create(self, section)
	section_number = get_new_section_number()
	data = { owner = arg[1], enabled = 1 }
	newSelection = m.uci:section("voice_pbx", "call_filter_rule", "call_filter_rule" .. section_number , data)
end

-- Called when a call filter rule is being deleted
function s.remove(self, section)
        TypedSection.remove(self, section)
end

direction = s:option(ListValue, "direction", "Direction")
direction:value("outgoing", "Outgoing")
direction:value("incoming", "Incoming")
direction.default = "outgoing"

user = s:option(ListValue, "user", "User")
user:value("*", "Any")
line_nr = 0
-- DECT
for i = 1, dectCount do
	user:value("BRCM/" .. line_nr, "DECT " .. i)
	line_nr = line_nr + 1
end
-- FXS
for i = 1, fxsCount do
	user:value("BRCM/" .. line_nr, "Tel " .. i)
	line_nr = line_nr + 1
end
-- SIP users
vc.foreach_user({'sip'},
        function(v)
                user:value("SIP/" .. v['user'], v['name'])
        end
)
user.default = "*"
user.custom = false
user:depends("direction", "outgoing")
user.rmempty = true

s:option(Value, "extension", "Extension")
enabled = s:option(Flag, "enabled", "Enabled")
enabled.default = 1

return m
