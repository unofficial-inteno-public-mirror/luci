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

-- This function is called when a new profile should be created i.e. when
-- user presses the "Add" button. We create a new section, name it, and
-- proceed to detailed editor.
function s.create(self, section)
	profile_section_nr = get_new_section_number()
	data = {}
	newProfile = m.uci:section("voice_pbx", "opening_hours_profile", "opening_hours_profile" .. profile_section_nr, data)

	local ts_section_nr = 0
	while m.uci:get("voice_pbx", "timespan" .. ts_section_nr) do
		ts_section_nr = ts_section_nr + 1
	end
	data = { owner = "opening_hours_profile" .. profile_section_nr, name = "Always open", time_range = "*", days_of_week = "*", days_of_month = "*", months = "*" }
	newTimespan = m.uci:section("voice_pbx", "timespan", "timespan" .. ts_section_nr, data)
	luci.http.redirect(s.extedit % newProfile)
end

-- Called when a profile is being deleted
function s.remove(self, section)
	m.uci:foreach("voice_pbx", "timespan",
		function(s1)
			if s1["owner"] == section then
				m.uci:delete("voice_pbx", s1[".name"])
			end
		end
	)
	TypedSection.remove(self, section)
end

queue_name = s:option(DummyValue, "name", "Name")

return m
