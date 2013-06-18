
m = Map("snmpd")

-- SNMP --
s = m:section(NamedSection, "daemon", "snmp", translate("SNMP"))
s.anonymous = true

en = s:option(Flag, "enabled", translate("Enable SNMP"))
en.rmempty = false

return m
