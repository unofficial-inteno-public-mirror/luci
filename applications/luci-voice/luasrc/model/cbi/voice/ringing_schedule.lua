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

local ds = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"
local vrsc = require "luci.model.cbi.voice.ringing_schedule_common"
require "luci.util"

m = Map("voice_client", "Ringing Schedule", "Define schedules when your phones should ring or not")

s = m:section(TypedSection, "ringing_status")
s.anonymous = true

status = s:option(ListValue, 'enabled', "Enable ringing scheduling")
status.default = "0"
status.rmempty = true
status:value("1", "Enabled")
status:value("0", "Disabled")

enabled = s:option(ListValue, 'status', "During the times given below, ringing should be")
enabled.default = "0"
enabled.rmempty = true
enabled:value("1", "Enabled")
enabled:value("0", "Disabled")

s = m:section(TypedSection, "ringing_schedule")
s.template  = "cbi/tblsection"
s.optional = true
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/ringing_schedule/%s")

section_count = 0
m.uci:foreach("voice_client", "ringing_schedule",
	function(s1)
		section_count = section_count + 1
	end
)

function get_new_section_number()
	local section_nr = 0
	while m.uci:get("voice_client", "ringing_schedule" .. section_nr) do
		section_nr = section_nr + 1
	end
	return section_nr
end

function s.create(self, section)
	data = {}
	new_section = m.uci:section("voice_client", "ringing_schedule", "ringing_schedule" .. get_new_section_number(), data)
	luci.http.redirect(s.extedit % new_section)
end

days = s:option(DummyValue, "days", "Days")
function days.cfgvalue(self, section)
	local weekdays = {
		["Monday"] = true,
		["Tuesday"] = true,
		["Wednesday"] = true,
		["Thursday"] = true,
		["Friday"] = true,
		["Saturday"] = true,
		["Sunday"] = true,
	}
	local days = m.uci.get("voice_client", section, "days")
	local days_list = {}
	for k,v in pairs(luci.util.split(days, " ")) do
		if weekdays[v] then
			if not days_list[v] then
				table.insert(days_list, v)
			end
			days_list[v] = v
		end
	end
	
	local function sort_weekdays(a, b)
        	local weekdays = {                                                                                                                                             
			["Monday"] = 0,
			["Tuesday"] = 1,
			["Wednesday"] = 2,
			["Thursday"] = 3,
			["Friday"] = 4,
			["Saturday"] = 5,
			["Sunday"] = 6,
		}
		return weekdays[a]<weekdays[b]
	end
	table.sort(days_list, sort_weekdays)
	
	return table.concat(days_list, ", ")
end

time = s:option(DummyValue, "time", "Time")
function time.cfgvalue(self, section)
	local time = m.uci:get("voice_client", section, "time")
	
	if vrsc.validate_time(time) == nil then
		return "Invalid time"
	end
	return time
end

sip_service_provider = s:option(DummyValue, "sip_service_provider", "SIP Account")
function sip_service_provider.cfgvalue(self, section)
	sip_service_provider = {}
	local provider = m.uci:get("voice_client", section, "sip_service_provider")
	if provider ~= nil then
		for k,v in pairs(luci.util.split(provider, " ")) do
			provider = m.uci:get("voice_client", v, "name")
			if provider then
				table.insert(sip_service_provider, provider)
			else
				table.insert(sip_service_provider, 'Unknown')
			end
		end
	end
	return table.concat(sip_service_provider, ", ")
end

return m
