--[[
LuCI - Lua Configuration Interface

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

-- http://luci.subsignal.org/trac/browser/luci/trunk/applications/luci-radvd/luasrc/model/cbi/radvd.lua?rev=6
local ds = require "luci.dispatcher"

m = Map ("voice_pbx", "Opening Hours")
s = m:section(TypedSection, "opening_hours_profile")
s.template = "voice_pbx/tblsection_refresh"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/voice_opening_hours/%s")

section_count = 0
m.uci:foreach("voice_pbx", "opening_hours_profile",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_pbx", "opening_hours_profile" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new queue should be created i.e. when
-- user presses the "Add" button. We create a new section, name it, and
-- proceed to detailed editor.
function s.create(self, section)
	section_nr = get_new_section_number()
	data = {}
	newQueue = m.uci:section("voice_pbx", "opening_hours_profile", "opening_hours_profile" .. section_nr, data)
	luci.http.redirect(s.extedit % newQueue)
end

-- Called when a queue is being deleted
function s.remove(self, section)
	TypedSection.remove(self, section)
end

queue_name = s:option(DummyValue, "name", "Name")

return m
