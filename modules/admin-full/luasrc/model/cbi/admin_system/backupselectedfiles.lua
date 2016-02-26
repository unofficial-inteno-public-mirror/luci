local uci = require("luci.model.uci").cursor()

m = Map("backup", translate("Backup Settings"))
m:append(Template("admin_system/backupfiles"))

s = m:section(TypedSection, "service", translate("Select the services/settings to backup"))
s.anonymous = true
s.addremove = false
s.template = "cbi/tblsection"

desc = s:option(DummyValue, "desc", translate("Service"))

keep = s:option(Flag, "keep", "Keep")
keep.rmempty = true
keep.default = "1"

detail = s:option(DummyValue, "detail")

--file = s:option(DynamicList, "file", translate("Files"))

return m

