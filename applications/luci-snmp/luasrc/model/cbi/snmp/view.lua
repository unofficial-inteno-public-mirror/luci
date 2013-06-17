
m = Map("snmpd")

-- View --
s = m:section(TypedSection, "view", translate("View"))
s.anonymous = true
s.addremove = true

s:option(Value, "viewname", translate("View Name"))
s:option(Value, "type", translate("Type"))
s:option(Value, "oid", translate("OID"))
s:option(Value, "mask", translate("Mask"))

return m
