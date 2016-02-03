m = Map("buttons", "Buttons")
s = m:section(TypedSection, "button", translate("Configure Buttons"))
s.addremove = false
s.template = "cbi/tblsection"

en = s:option(Flag, "enable", "Enable")
en.rmempty = true
en.default = "1"

--if TECUSER then
--minp = s:option(Value, "minpress", "Minimum Press Time (ms)")
--minp.rmempty = true
--minp.datatype = "uinteger"
--minp.default = "1000"
--end

return m

