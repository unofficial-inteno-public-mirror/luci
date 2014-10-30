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
m = Map("voice_client", "IVR")
m.redirect = dsp.build_url("admin/services/voice/ivr")
s = m:section(NamedSection, arg[1], "ivr")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_client", arg[1]) ~= "ivr" then
	luci.http.redirect(m.redirect)
	return
else
	local extension = m:get(arg[1], "extension")
	if not extension or #extension == 0 then
		m.title = "New IVR"
	else
		m.title = "Edit IVR"
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

mailbox = s:option(ListValue, "mailbox", "Mailbox", "Please note that voice mail is only used when the IVR is closed")
m.uci:foreach("voice_client", "mailbox",
	function(s1)
		mailbox:value(s1[".name"], s1["name"])
	end
)	
mailbox:value("-", "-")
mailbox.default = "-"

m.uci:foreach("voice_client", "opening_hours_profile",
	function(v)
		opening_hours:value(v['.name'], v['name'])
		mailbox:depends("opening_hours_profile", v['.name'])
	end
)
opening_hours:value("-", "-")
opening_hours.default = "-"

-- Extension, must be unique (useful to transfer a call to the queue)
extension = s:option(Value, "extension", "Extension", "Extension to call this IVR")
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

-- Enabled checkbox
e = s:option(Flag, "enabled", "IVR Enabled")
e.default = 0

sound_file = s:option(ListValue, "sound_file", "Sound", "Sound file played back when someone calls the IVR")
sound_file:value("-", "-")
for _,v in pairs(vc.get_recordings()) do
	sound_file:value("/usr/lib/asterisk/recordings/" .. v["name"], v["timestamp"])
end
for _,v in pairs(vc.get_extra_sounds()) do
	sound_file:value("/usr/lib/asterisk/extra/" .. v["name"], v["name"])
end

s = m:section(TypedSection, "tone_selection", "Tone Selections")
function s.filter(self, section)
        owner = m.uci:get("voice_client", section, 'owner')
	if owner == arg[1] then
		return true
	end
        return false
end
s.template = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/ivr_details/%s")

-- Find the lowest free section number
function get_new_section_number()
        local section_nr = 0
        while m.uci:get("voice_client", "tone_selection" .. section_nr) do
                section_nr = section_nr + 1
        end
        return section_nr
end

-- This function is called when a new tone selection should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s.create(self, section)
	if m.save == false then
		return
	end
	section_number = get_new_section_number()
	data = { owner = arg[1] }
	newSelection = m.uci:section("voice_client", "tone_selection", "tone_selection" .. section_number , data)
	luci.http.redirect(s.extedit % newSelection)
end

-- Called when an account is being deleted
function s.remove(self, section)
        TypedSection.remove(self, section)
end

s:option(DummyValue, "number", "Number")
enabled = s:option(DummyValue, "enabled", "Enabled")
function enabled.cfgvalue(self, section)
	enabled = Value.cfgvalue(self, section)
	return enabled == "1" and "Yes" or "No"
end
user = s:option(DummyValue, "user", "Call")
function user.cfgvalue(self, section)
	t = Value.cfgvalue(self, section)
	return vc.user2name(t)
end

return m
