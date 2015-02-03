module("luci.controller.sfp", package.seeall)

function index()
	local pages

	pages = entry({"admin", "status", "sfp"}, template("admin_status/sfp"), luci.i18n.translate("SFP"))

end

