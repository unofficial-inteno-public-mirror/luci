local sys = require "luci.sys"
local utl = require "luci.util"

m = Map("dect", translate("DECT Configuration"))

s = m:section(TypedSection, "dect")
s.anonymous = true


dect = s:option(Flag, "radio", "DECT Radio")
dect.rmempty = false


return m

