
m = Map("snmpd")

-- Agent --
s = m:section(TypedSection, "agent", translate("Agent"))
s.anonymous = true
s.addremove = true

s:option(Value, "agentaddress", translate("Agent Address"))

return m
