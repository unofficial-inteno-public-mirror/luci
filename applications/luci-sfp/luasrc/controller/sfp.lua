module("luci.controller.sfp", package.seeall)

function index()
	if luci.sys.exec("ubus list sfp* 2>/dev/null") == "" then
		return
	end

	local pages

	pages = entry({"admin", "status", "sfp"}, template("admin_status/sfp"), luci.i18n.translate("SFP"))

end

