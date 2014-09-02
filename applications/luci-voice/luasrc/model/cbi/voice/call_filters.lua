--[[
LuCI - Lua Configuration Interface

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

-- http://luci.subsignal.org/trac/browser/luci/trunk/applications/luci-radvd/luasrc/model/cbi/radvd.lua?rev=6
local ds = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

m = Map("voice_client", "Call Filters")
s = m:section(TypedSection, "call_filter")
s.template = "voice/tblsection_refresh"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/call_filters/%s")

section_count = 0
m.uci:foreach("voice_client", "call_filter",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_client", "call_filter" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new call filter should be created i.e. when
-- user presses the "Add" button. We create a new section, name it, and
-- proceed to detailed editor.
function s.create(self, section)
	section_nr = get_new_section_number()
	data = { name = "Untitled Call Filter", enabled = 0, incoming = "blacklist", outgoing = "blacklist" }
	newQueue = m.uci:section("voice_client", "call_filter", "call_filter" .. section_nr, data)
	luci.http.redirect(s.extedit % newQueue)
end

-- Called when a call filter is being deleted
function s.remove(self, section)
	-- Remove all rules belonging to this call filter
	m.uci:foreach("voice_client", "call_filter_rule",
		function(s1)
			if s1["owner"] == section then
				m.uci:delete("voice", s1[".name"])
			end
		end
	)
	TypedSection.remove(self, section)
end

s:option(DummyValue, "name", "Name")
e = s:option(DummyValue, "enabled", "Enabled")
function e.cfgvalue(self, section)
	enabled = Value.cfgvalue(self, section)
	return enabled == "1" and "Yes" or "No"
end

return m
