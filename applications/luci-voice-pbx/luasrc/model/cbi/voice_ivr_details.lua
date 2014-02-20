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
m = Map("voice_pbx", "IVR")
m.redirect = dsp.build_url("admin/services/voice/voice_ivr")
s = m:section(NamedSection, arg[1], "ivr")
s.anonymous = true
s.addremove = false

-- Set page title, or redirect if we have nothing to edit
if m.uci:get("voice_pbx", arg[1]) ~= "ivr" then
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

s:option(Value, "name", "Name", "Display name")

-- Extension, must be unique (useful to transfer a call to the queue)
extension = s:option(Value, "extension", "Extension", "Extension to call this IVR")
function extension.validate(self, value, section)
	return vc.validate_extension(value, m.uci:get("voice_pbx", arg[1], 'user'))
end

-- Enabled checkbox
e = s:option(Flag, "enabled", "IVR Enabled")
e.default = 0

sound_file = s:option(Value, "sound_file", "Sound", "Sound file played back when someone calls the IVR")

s = m:section(TypedSection, "tone_selection", "Tone Selections")
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
s.extedit = ds.build_url("admin/services/voice/voice_ivr_details/%s")

-- Find the lowest free section number
function get_new_section_number()
        local section_nr = 0
        while m.uci:get("voice_pbx", "tone_selection" .. section_nr) do
                section_nr = section_nr + 1
        end
        return section_nr
end

-- This function is called when a new tone selection should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s.create(self, section)
	section_number = get_new_section_number()
	data = { owner = arg[1] }
	newSelection = m.uci:section("voice_pbx", "tone_selection", "tone_selection" .. section_number , data)
	luci.http.redirect(s.extedit % newSelection)
end

-- Called when an account is being deleted
function s.remove(self, section)
        TypedSection.remove(self, section)
end

s:option(DummyValue, "number", "Number")
s:option(Flag, "enabled", "Enabled")
user = s:option(DummyValue, "user", "User")
function user.cfgvalue(self, section)
	t = Value.cfgvalue(self, section)
	return vc.user2name(t)
end

return m
