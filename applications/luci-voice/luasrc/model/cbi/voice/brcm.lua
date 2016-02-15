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

local hasdect = " "
if tonumber(luci.sys.exec("db -q get hw.board.hasDect")) == 1 then
        hasdect = " and DECT "
end
local title = "FXS" .. hasdect .. "Settings"

m = Map("voice_client", title)
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
sip_provider = s:option(ListValue, "sip_account", "Call out using SIP provider")
m.uci:foreach("voice_client", "sip_service_provider",
	function(s1)
		if s1.enabled == "1" then
			sip_provider:value(s1['.name'], s1.name)
		end
	end)
sip_provider:value("-", "-")
sip_provider.default = "-"

autodial = s:option(Value, "autodial", "Hotline number*")
function autodial.validate(self, value, section)
    if datatypes.phonedigit(value) then
        return value
    else
        return nil, value .. " is not a valid number"
    end
end

autodial_timeout = s:option(Value, "autodial_timeout", "Hotline delay (milliseconds)*")
function autodial_timeout.validate(self, value, section)
    if datatypes.uinteger(value) then
        return value
    end
    return nil, "Hotline delay must be a positive number of milliseconds"                                                                           
end

mailbox = s:option(ListValue, "mailbox", "Mailbox")
m.uci:foreach("voice_client", "mailbox",
	function(s1)
		mailbox:value(s1[".name"], s1["name"])
	end
)	
mailbox:value("-", "-")
mailbox.default = "-"

comment = m:section(SimpleSection, "", "* Automatically dial a predetermined number after a delay, if user has not pressed any button(s). Leave empty to disable.")
comment.anonymous = true

return m
