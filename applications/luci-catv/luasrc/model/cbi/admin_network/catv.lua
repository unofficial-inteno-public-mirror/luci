
m = Map("catv",translate("CATV Configure"))


s = m:section(TypedSection, "service",  translate("Enable disable CATV module and choose a filter"))
s.addremove = false


enapoll = s:option(Flag, "enable", translate("Enabled"))
enapoll.enabled = "on"
enapoll.disabled = "off"
filter = s:option(ListValue, "filter", translate("Filter"))
filter:value("1", translate("47MHz ~ 1000MHz"))
filter:value("2", translate("47MHz ~ 591MHz"))
filter:value("3", translate("47MHz ~ 431MHz"))
return m

