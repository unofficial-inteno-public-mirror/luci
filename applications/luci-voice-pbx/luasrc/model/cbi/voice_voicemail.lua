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

m = Map ("voice_pbx", "Voice Mail")
s = m:section(TypedSection, "mailbox")
s.template  = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/voice_voicemail/%s")

section_count = 0
m.uci:foreach("voice_pbx", "mailbox",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_pbx", "mailbox" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new mailbox should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s.create(self, section)
	if section_count < 8 then
		section_number = get_new_section_number()
		data = {}
		newAccount = m.uci:section("voice_pbx", "mailbox", "mailbox" .. section_number , data)
		luci.http.redirect(s.extedit % newAccount)
	end
end

-- Called when an account is being deleted
function s.remove(self, section)
	TypedSection.remove(self, section)
end

account_name = s:option(DummyValue, "user", "User")
function account_name.cfgvalue(self, section)
	local v = "-"
	local l = Value.cfgvalue(self, section)
	m.uci:foreach("voice_pbx", "brcm_line",
		function(s1)
			if s1['.name'] == l then
				v = s1['name']
			end
		end
	)
	m.uci:foreach("voice_pbx", "sip_user",
		function(s1)
			if s1['.name'] == l then
				v = s1['name']
			end
		end
	)
	return v
end

e = s:option(Flag, "enabled", "Mailbox Enabled")
e.default = 0

-- Settings -------------------------------------------------------------------
voicemail = m:section(TypedSection, "voicemail", "Settings")
voicemail.anonymous = true

extension = voicemail:option(Value, "extension", "Voice mail extension")
extension.default = "6500"

return m
