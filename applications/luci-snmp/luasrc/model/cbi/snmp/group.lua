
m = Map("snmpd")

-- Group --
s = m:section(TypedSection, "group", translate("Group"))
s.anonymous = true
s.addremove = true

s:option(Value, "group", translate("Group"))
s:option(Value, "version", translate("Version"))
s:option(Value, "secname", translate("SecName"))

return m
