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
local vc = require "luci.model.cbi.voice.common"

default_extension = 0

m = Map ("voice", "FXS and DECT Settings")
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
function title.cfgvalue(self, section)
	return vc.user2name(section)
end

-- Show line extension
exten = s:option(Value, "extension", "Extension")
exten.default = default_extension..default_extension..default_extension..default_extension
default_extension = default_extension + 1
function exten.validate(self, value, section)
	return vc.validate_extension(value, section)
end

-- Show call waiting setting        
cw = s:option(Flag, "callwaiting", "Call Waiting")
cw.default = "0"
cw.disabled = "0"
cw.enabled = "1"

-- Show CLIR setting
clir = s:option(Flag, "clir", "CLIR")
clir.default = "0"
clir.disabled = "0"
clir.enabled = "1"

-- Show SIP account selection
sip_provider = s:option(ListValue, "sip_provider", "Call out using SIP provider")
m.uci:foreach("voice", "sip_service_provider",
	function(s1)
		if s1.enabled == "1" then
			sip_provider:value(s1['.name'], s1.name)
		end
	end)
sip_provider:value("-", "-")
sip_provider.default = "-"

return m
