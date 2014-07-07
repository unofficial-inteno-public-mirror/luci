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

m = Map ("voice", "SIP Service Providers")
s = m:section(TypedSection, "sip_service_provider")
s.template = "voice/tblsection_refresh"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/sip/%s")

section_count = 0
m.uci:foreach("voice", "sip_service_provider",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice", "sip" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

-- This function is called when a new account should be created i.e. when
-- user presses the "Add" button. We create a new section, name it, and
-- proceed to detailed editor.
function s.create(self, section)
	if section_count < 8 then
		section_number = get_new_section_number()
		data = { name = "Account " .. section_number + 1 }
		newAccount = m.uci:section("voice", "sip_service_provider", "sip" .. section_number, data)
		luci.http.redirect(s.extedit % newAccount)
	end
end

-- Called when an account is being deleted
function s.remove(self, section)
	-- Disable calling out using this account
	vc.foreach_user({'brcm', 'sip'},
		function(v)
			name = v['.name']
			if v.sip_account == section then
				m.uci:set("voice", name, "sip_account", "-")
			end
		end
	)
	-- Remove call filters associated to this account
	m.uci:foreach("voice", "call_filter",
		function(s1)
			if s1['sip_provider'] == section then
				m.uci:set("voice", s1[".name"], "sip_provider", "-")
			end
		end
	)
	m.uci:foreach("voice", "mailbox",
		function(s1)
			if s1["user"] == section then
				m.uci:set("voice", s1[".name"], "user", "-")
			end
		end
	)
	TypedSection.remove(self, section)
end

account_name = s:option(DummyValue, "name", "SIP Account")

-- Parse function for enabled Flags, perform validation
-- to make sure the account is not used for outgoing calls from
-- some line. If it is, we should not allow it to be disabled.
function parse_enabled(self, section)
	Flag.parse(self, section)
	local fvalue = self:formvalue(section)
                                                                                                                                         
	if not fvalue then
		vc.foreach_user({'brcm', 'sip'},
			function(v)
				name = v['.name']
				if v.sip_account == section then
					m.uci:set("voice", name, "sip_account", "-")
				end
			end
		)
	end
end

e = s:option(Flag, "enabled", "Account Enabled")
e.default = 0
e.parse = parse_enabled

s:option(DummyValue, "user", "Username")
s:option(DummyValue, 'domain', 'SIP domain name')

l = s:option(DummyValue, "call_lines", "Incoming calls to line")
function l.cfgvalue(self, section)
	local v	= ""
	local l = Value.cfgvalue(self, section)	
	if l then
		lines = string.split(l, " ")
		for i,l in ipairs(lines) do
			info = string.split(l, "/")
			if i > 1 then
				v = v .. ", "
			end
			if (info[1] == "SIP") then
				vc.foreach_user({'sip'},
					function(s1)
						if (s1['user'] == info[2]) then
							v = v .. s1['name']
							return
						end
					end
				)
			elseif (info[1] == "BRCM") then
				lineId = tonumber(info[2]:match("%d+"))
			
				if (lineId < dectCount) then
					v = v .. "DECT " .. lineId + 1
				else
					v = v .. "Tel " .. lineId - dectCount + 1
				end
			end
		end
	end
	return v
end

r = s:option(DummyValue, "registration_state", "Registered")
function r.cfgvalue(self, section)
	local state = "N/A"

	sip_registry = luci.sys.exec("asterisk -rx 'sip show registry'")

	lines = string.split(sip_registry, "\n")
	for _, line in ipairs(lines) do
		host, port = line:sub(1,40):match("^%s*(sip%d+):(%d+)%s*$")
		if host then
			account = line:sub(0, 4):match("^%s*(.-)%s*$")
			if account == section then
				acc_state = line:sub(71, 91):match("^%s*(.-)%s*$")
				if acc_state == "Registered" then
					acc_state = "Yes"
				else
					acc_state = string.format("No (%s)", acc_state)
				end
				state = acc_state
				break
			end
		end
	end
	return state
end

return m
