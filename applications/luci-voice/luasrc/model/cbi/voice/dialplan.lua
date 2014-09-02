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

m = Map("voice_client", translate("Custom dialplan settings"),
"Allows specification of extra entries in the local dialplan. This will be included for all lines.")

s = m:section(TypedSection, "dialplan")
s.anonymous = true

e = s:option(Flag, "custom_outgoing_enabled", translate("Custom outgoing dialplan enabled"))
e.default = 0

e = s:option(Flag, "custom_incoming_enabled", translate("Custom incoming dialplan enabled"))
e.default = 0

e = s:option(Flag, "custom_hangup_enabled", translate("Custom hangup dialplan enabled"))
e.default = 0

custom = s:option(Value, 'dialplan', '')
custom.template = "cbi/tvalue"
custom.rows = 20

function custom.cfgvalue(self, section)
        return nixio.fs.readfile("/etc/asterisk/extensions_extra.conf")
end

function custom.write(self, section, value)
        value = value:gsub("\r\n?", "\n")
        nixio.fs.writefile("/etc/asterisk/extensions_extra.conf", value)
end

return m

