
m = Map("snmpd")

-- Pass --
s = m:section(TypedSection, "pass", translate("Pass"))
s.anonymous = true
s.addremove = true

persist = s:option(Flag, "persist", translate("Persist"))
persist.rmempty = false
s:option(Value, "priority", translate("Priority"))
s:option(Value, "miboid", translate("MIB OID"))
s:option(Value, "prog", translate("Program"))

return m

