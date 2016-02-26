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

m = Map("voice_client", "SIP Service Providers")
s = m:section(TypedSection, "sip_service_provider")
s.template = "voice/tblsection_refresh"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/sip/%s")

section_count = 0
m.uci:foreach("voice_client", "sip_service_provider",
	function(s1)
		section_count = section_count + 1
	end
)

-- Find the lowest free section number
function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_client", "sip" .. section_nr) do
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
		data = { name = "Account " .. section_number + 1, enabled = 0 }
		newAccount = m.uci:section("voice_client", "sip_service_provider", "sip" .. section_number, data)
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
				m.uci:set("voice_client", name, "sip_account", "-")
			end
		end
	)
	-- Remove call filters associated to this account
	m.uci:foreach("voice_client", "call_filter",
		function(s1)
			if s1['sip_provider'] == section then
				m.uci:set("voice_client", s1[".name"], "sip_provider", "-")
			end
		end
	)
	m.uci:foreach("voice_client", "mailbox",
		function(s1)
			if s1["user"] == section then
				m.uci:set("voice_client", s1[".name"], "user", "-")
			end
		end
	)
	TypedSection.remove(self, section)
end

account_name = s:option(DummyValue, "name", "SIP Account")

e = s:option(DummyValue, "enabled", "Account Enabled")
function e.cfgvalue(self, section)
	enabled = Value.cfgvalue(self, section)
	return enabled == "1" and "Yes" or "No"
end
e.default = 0

s:option(DummyValue, "user", "Username")
s:option(DummyValue, 'domain', 'SIP domain name')

l = s:option(DummyValue, "target", "Incoming calls to")
function l.cfgvalue(self, section)
	local v	= ""
	local target = Value.cfgvalue(self, section)

	if target == "queue" then
		q = m.uci:get("voice_client", section, "call_queue")
		if q then
			v = vc.user2name(q)
		end
	elseif target == "ivr" then
		i = m.uci:get("voice_client", section, "call_ivr")
		if i then
			v = vc.user2name(i)
		end
	else
		local l = m.uci:get("voice_client", section, "call_lines")
		if l then
			lines = {}
			for i,l in ipairs(string.split(l, " ")) do
				if (l:sub(1,3) == "SIP") then				
					user = l:sub(5)
					vc.foreach_user({'sip'},
						function(s1)
							if (s1['user'] == user and s1['name']) then
								table.insert(lines, s1['name'])
								return
							end
						end
					)
				else
					lineId = tonumber(l:match("%d+"))
					lineNum = "brcm%d" %lineId
					table.insert(lines, m.uci:get("voice_client", lineNum, "name") or lineNum:upper())
				end
			end
			return table.concat(lines, ", ")
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
