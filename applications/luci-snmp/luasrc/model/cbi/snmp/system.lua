
m = Map("snmpd", translate("SNMP"))

-- System --
s = m:section(TypedSection, "system", translate("System"))
s.anonymous = true
s.addremove = true

s:option(Value, "sysLocation", translate("Location"))
s:option(Value, "sysContact", translate("Contact"))
s:option(Value, "sysName", translate("Name"))
s:option(Value, "sysServices", translate("Services"))
s:option(Value, "sysDescr", translate("Description"))
s:option(Value, "sysObjectID", translate("Object ID"))

return m
