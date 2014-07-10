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

-- Voice Mail for SIP providers
m = Map ("voice", "Voice Mail")
s1 = m:section(TypedSection, "mailbox", "Mailboxes")
s1.template  = "cbi/tblsection"
s1.anonymous = true
s1.addremove = true
s1.extedit = ds.build_url("admin/services/voice/voicemail/%s")

section_count = 0
m.uci:foreach("voice", "mailbox",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice", "mailbox" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new mailbox should be configured i.e. when
-- user presses the "Add" button. We create a new section,
-- and proceed to detailed editor.
function s1.create(self, section)
	section_number = get_new_section_number()
	data = { user = "-", enabled = 0 }
	newAccount = m.uci:section("voice", "mailbox", "mailbox" .. section_number , data)
	luci.http.redirect(s1.extedit % newAccount)
end

-- Called when an account is being deleted
function s1.remove(self, section)
	TypedSection.remove(self, section)
end

account_name = s1:option(DummyValue, "user", "Belongs to")
function account_name.cfgvalue(self, section)
	local v = vc.user2name(Value.cfgvalue(self, section))
	if not v or v:len() == 0 then
		v = "-"
	end
	return v
end

e = s1:option(DummyValue, "enabled", "Enabled")
function e.cfgvalue(self, section)
	enabled = Value.cfgvalue(self, section)
	return enabled == "1" and "Yes" or "No"
end
e.default = 0

-- Settings -------------------------------------------------------------------
vc.add_section("voicemail")
voicemail = m:section(TypedSection, "voicemail", "Settings")
voicemail.anonymous = true
function voicemail.filter(self, section)
	if section ~= "voicemail" then
		return nil
	end
	return section
end

timeout = voicemail:option(Value, "timeout", "Timeout", "Number of seconds to ring before incoming call is transferred to voicemail")
timeout.default = "30"
function timeout.validate(self, value, section)
	if not value:match("^%d+$") then
		return nil, "Invalid timeout format"
	end
	return value
end

extension = voicemail:option(Value, "extension", "Voice mail extension")
extension.default = "6500"
function extension.validate(self, value, section)
	return vc.validate_extension(value)
end

return m
