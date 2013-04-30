
m = Map("snmpd", translate("SNMP"))

-- Agent --
s = m:section(TypedSection, "agent", translate("Agent"))
s.anonymous = true
s.addremove = true

s:option(Value, "agentaddress", translate("Agent Address"))


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


-- Com2sec --
s = m:section(TypedSection, "com2sec", "Com2sec")
s.anonymous = true
s.addremove = true

s:option(Value, "community", translate("Community"))
s:option(Value, "source", translate("Source"))
s:option(Value, "secname", translate("SecName"))


-- Group --
s = m:section(TypedSection, "group", translate("Group"))
s.anonymous = true
s.addremove = true

s:option(Value, "group", translate("Group"))
s:option(Value, "version", translate("Version"))
s:option(Value, "secname", translate("SecName"))


-- View --
s = m:section(TypedSection, "view", translate("View"))
s.anonymous = true
s.addremove = true

s:option(Value, "viewname", translate("View Name"))
s:option(Value, "type", translate("Type"))
s:option(Value, "oid", translate("OID"))
s:option(Value, "mask", translate("Mask"))


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


-- Pass --
s = m:section(TypedSection, "pass", translate("Pass"))
s.anonymous = true
s.addremove = true

persist = s:option(Flag, "persist", translate("Persist"))
persist.rmempty = false
s:option(Value, "priority", translate("Priority"))
s:option(Value, "miboid", translate("MIB OID"))
s:option(Value, "prog", translate("Program"))


-- Exec --
s = m:section(TypedSection, "exec", translate("Exec"))
s.anonymous = true
s.addremove = true

s:option(Value, "name", translate("Name"))
s:option(Value, "miboid", translate("MIB OID"))
s:option(Value, "prog", translate("Program"))
s:option(Value, "args", translate("Arguments"))


return m
