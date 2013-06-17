
m = Map("snmpd")

-- Exec --
s = m:section(TypedSection, "exec", translate("Exec"))
s.anonymous = true
s.addremove = true

s:option(Value, "name", translate("Name"))
s:option(Value, "miboid", translate("MIB OID"))
s:option(Value, "prog", translate("Program"))
s:option(Value, "args", translate("Arguments"))

return m
