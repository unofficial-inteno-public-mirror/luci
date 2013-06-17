
m = Map("snmpd")

-- Com2sec --
s = m:section(TypedSection, "com2sec", "Com2sec")
s.anonymous = true
s.addremove = true

s:option(Value, "community", translate("Community"))
s:option(Value, "source", translate("Source"))
s:option(Value, "secname", translate("SecName"))

return m
