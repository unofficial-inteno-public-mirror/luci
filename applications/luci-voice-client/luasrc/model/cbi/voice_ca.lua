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

m = Map ("voice_client", translate("Trusted Certificate Authorities"),
"Allows specification of trusted SSL certificate authorities (issuers). Issuer certificates should be in PEM-format. <br>Paste the full certificate including '-----BEGIN CERTIFICATE-----' and '-----END CERTIFICATE-----' below.")

s = m:section(TypedSection, "ca")
s.anonymous = true

ca = s:option(Value, 'ca', '')
ca.template = "cbi/tvalue"
ca.rows = 20

function ca.cfgvalue(self, section)
	return nixio.fs.readfile("/etc/asterisk/ssl/ca.pem")
end

function ca.write(self, section, value)
	value = value:gsub("\r\n?", "\n")
	nixio.fs.writefile("/etc/asterisk/ssl/ca.pem", value)
end

return m

