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

m = Map ("voice", "SIP Users")
s = m:section(TypedSection, "sip_user")
s.template  = "cbi/tblsection"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/sip_users/%s")

section_count = 0
m.uci:foreach("voice", "sip_user",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice", "sip_user" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new account should be created i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s.create(self, section)
	if section_count < 8 then
		section_number = get_new_section_number()
		data = { name = "New SIP user" }
		newAccount = m.uci:section("voice", "sip_user", "sip_user" .. section_number, data)
		luci.http.redirect(s.extedit % newAccount)
	end
end

-- Called when an account is being deleted
function s.remove(self, section)
	m.uci:foreach("voice", "mailbox",
		function(s1)
			if s1["user"] == section then
				m.uci:set("voice", s1[".name"], "user", "-")
			end
		end
	)
	TypedSection.remove(self, section)
end

account_name = s:option(DummyValue, "name", "SIP User")

e = s:option(Flag, "enabled", "Account Enabled")
e.default = 0

s:option(DummyValue, "user", "Username")

s:option(DummyValue, "extension", "Extension")
s:option(DummyValue, "host", "Host")

return m
