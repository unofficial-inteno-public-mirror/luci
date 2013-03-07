module("luci.controller.admin.iup", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/provisioning") then
		return
	end
	require("luci.i18n")
	luci.i18n.loadc("iup")
	
	local page = entry({"admin", "system", "iup"}, cbi("iup/iup"), luci.i18n.translate("Provisioning"))
	page.i18n = "iup"
	page.dependent = true
end
