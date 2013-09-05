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

-- Check line counts
lineInfo = luci.sys.exec("/usr/bin/brcminfo")
lines = string.split(lineInfo, "\n")
if #lines == 5 then
	dectInfo = lines[1]
	dectCount = tonumber(dectInfo:match("%d+"))
	fxsInfo = lines[2]
	fxsCount = tonumber(fxsInfo:match("%d+"))
	allInfo = lines[4]
	allCount = tonumber(allInfo:match("%d+"))
else
	dectCount = 0
	fxsCount = 0
	allCount = 0
end

m = Map ("voice_client", "SIP Service Providers")
s = m:section(TypedSection, "sip_service_provider")
s.template = "voice_client/tblsection_refresh"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/voice_sip/%s")

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
		data = { name = "Account " .. section_number + 1 }
		newAccount = m.uci:section("voice_client", "sip_service_provider", "sip" .. section_number, data)
		luci.http.redirect(s.extedit % newAccount)
	end
end

-- Called when an account is being deleted
-- Check that account is not in use before allowing deletion
function s.remove(self, section)
	m.uci:foreach("voice_client", "brcm_line",
		function(s1)
			line_name = s1['.name']
			if s1.sip_account == section then
				m.uci:set("voice_client", line_name, "sip_account", "-")
			end
		end
	)
	TypedSection.remove(self, section)
end


-- Parse function for enabled Flags, perform validation
-- to make sure the account is not used for outgoing calls from
-- some line. If it is, we should not allow it to be disabled.
function parse_enabled(self, section)
	Flag.parse(self, section)
	local fvalue = self:formvalue(section)
                                                                                                                                         
	if not fvalue then
		m.uci:foreach("voice_client", "brcm_line",
			function(s1)
				line_name = s1['.name']
				if s1.sip_account == section then
					m.uci:set("voice_client", line_name, "sip_account", "-")
				end
			end
		)
	end
end

account_name = s:option(DummyValue, "name", "SIP Account")

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
			lineId = tonumber(l:match("%d+"))
			if i > 1 then
				v = v .. ", "
			end
			if (lineId < dectCount) then
				v = v .. "DECT " .. l + 1
			else
				v = v .. "Tel " .. l - dectCount + 1
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
