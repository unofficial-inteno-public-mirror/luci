local sys = require "luci.sys"
local utl = require "luci.util"

m = Map("dect", translate("DECT"))

s = m:section(TypedSection, "dect", "DECT")
s.anonymous = true


dect = s:option(Flag, "disable", "Disable DECT Radio")
dect.rmempty = true


return m

