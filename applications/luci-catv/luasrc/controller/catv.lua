module("luci.controller.catv", package.seeall)

function index()
	local page 
	
	page = entry({"admin", "network", "catv"}, cbi("admin_network/catv"), luci.i18n.translate("CATV"))
	page.dependent = true

	page = entry({"admin", "status", "catv"}, template("admin_status/catv"),luci.i18n.translate("CATV"))

end

