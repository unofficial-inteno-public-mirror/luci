
m = Map("snmpd")

-- Access --
s = m:section(TypedSection, "access", translate("Access"))
s.anonymous = true
s.addremove = true

s:option(Value, "group", translate("Group"))
s:option(Value, "context", translate("Context"))
s:option(Value, "version", translate("Version"))
s:option(Value, "level", translate("Level"))
s:option(Value, "prefix", translate("Prefix"))
s:option(Value, "read", translate("Read"))
s:option(Value, "write", translate("Write"))
s:option(Value, "notify", translate("Notify"))

return m
