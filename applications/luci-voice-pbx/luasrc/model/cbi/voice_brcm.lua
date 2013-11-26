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

local datatypes = require("luci.cbi.datatypes")

-- Read line counts from driver
lineInfo = luci.sys.exec("/usr/bin/brcminfo")
lines = string.split(lineInfo, "\n")
line_nr = 0
if #lines == 5 then
	dectInfo = lines[1]
	dectCount = tonumber(dectInfo:match("%d+"))
	fxsInfo = lines[2]
	fxsCount = tonumber(fxsInfo:match("%d+"))
	allInfo = lines[4]
	allCount = tonumber(allInfo:match("%d"))
else
	dectCount = 0
	fxsCount = 0
	allCount = 0
end

default_extension = 0

m = Map ("voice_pbx", "Line Settings")
s = m:section(TypedSection, "brcm_line")
s.template  = "cbi/tblsection"
s.anonymous = true

-- Only show configuration for lines that actually exist
function s.filter(self, section)
	line_number = tonumber(section:match("%d+"))
	return line_number < allCount
end

-- Show line title
title = s:option(DummyValue, "name", "Line")

-- Show line extension
exten = s:option(Value, "extension", "Extension")
exten.default = default_extension..default_extension..default_extension..default_extension
default_extension = default_extension + 1
function exten.validate(self, value, section)
	if datatypes.phonedigit(value) then
		return value
	else
		return nil, value .. " is not a valid extension"
	end
end

-- Show SIP account selection
sip_account = s:option(ListValue, "sip_account", "Call out on SIP account")
m.uci:foreach("voice_pbx", "sip_service_provider",
	function(s1)
		if s1.enabled == "1" then
			sip_account:value(s1['.name'], s1.name)
		end
	end)
sip_account:value("-", "-")
sip_account.default = "-"

return m
