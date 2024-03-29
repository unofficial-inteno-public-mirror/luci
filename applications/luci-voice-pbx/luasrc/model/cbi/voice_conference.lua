--[[
    Copyright 2011 Iordan Iordanov <iiordanov (AT) gmail.com>

    This file is part of luci-pbx.

    luci-pbx is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    luci-pbx is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with luci-pbx.  If not, see <http://www.gnu.org/licenses/>.
]]--

-- http://luci.subsignal.org/trac/browser/luci/trunk/applications/luci-radvd/luasrc/model/cbi/radvd.lua?rev=6
local ds = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

m = Map ("voice_pbx", "Conference")
s1 = m:section(TypedSection, "conference_room")
s1.template  = "cbi/tblsection"
s1.anonymous = true
s1.addremove = true
s1.extedit = ds.build_url("admin/services/voice/voice_conference/%s")

section_count = 0
m.uci:foreach("voice_pbx", "conference_room",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_pbx", "conference_room" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new conference room should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s1.create(self, section)
	section_number = get_new_section_number()
	data = {}
	newAccount = m.uci:section("voice_pbx", "conference_room", "conference_room" .. section_number , data)
	luci.http.redirect(s1.extedit % newAccount)
end

-- Called when a conference room is being deleted
function s1.remove(self, section)
	TypedSection.remove(self, section)
end

s1:option(DummyValue, "name", "Name")
s1:option(DummyValue, "id", "ID")
s1:option(Flag, "enabled", "Enabled")

return m
