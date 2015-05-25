local sys = require "luci.sys"
local utl = require "luci.util"

m = Map("dect", translate("DECT Configuration"))

s = m:section(TypedSection, "dect")
s.anonymous = true


dect = s:option(ListValue, "radio", "DECT Radio")
dect.rmempty = false
dect:value("auto", "auto")
dect:value("on", "on")
dect:value("off", "off")

return m

