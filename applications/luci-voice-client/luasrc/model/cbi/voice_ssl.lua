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

m = Map ("voice_client", "TLS/SSL")

ssl = m:section(TypedSection, "sip_advanced", "")
ssl.anonymous = true

version = ssl:option(ListValue, "tls_version", "Version")
version:value("tlsv1", "TLS v1")
version:value("sslv3", "SSL v3")
version:value("sslv2", "SSL v2")
version.default = "tlsv1"

cipher = ssl:option(Value, "tls_cipher", "Cipher string")
cipher.default = "DES-CBC3-SHA"

ca = ssl:option(Value, 'ca', "Trusted CA", "Issuer certificates in PEM-format. Paste the full certificate including '-----BEGIN CERTIFICATE-----' and '-----END CERTIFICATE-----'.")
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

