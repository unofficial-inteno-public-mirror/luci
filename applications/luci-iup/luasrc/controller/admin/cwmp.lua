
module("luci.controller.admin.cwmp", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/cwmp") then
		return
	end
	require("luci.i18n")
	luci.i18n.loadc("cwmp")
	
	local page = entry({"admin", "system", "iup","cwmp"}, cbi("provisioning/cwmp"), luci.i18n.translate("TR-069"))
	page.i18n = "cwmp"
	page.dependent = true
end
