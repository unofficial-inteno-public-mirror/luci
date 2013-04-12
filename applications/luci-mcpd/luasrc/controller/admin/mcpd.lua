module("luci.controller.admin.mcpd", package.seeall)

function index()
	local page 
	
	page = entry({"admin", "network", "mcpd"}, cbi("admin_network/mcpd"), luci.i18n.translate("IGMP Proxy"))
	page.dependent = true

	pacge = entry({"admin", "status", "igmp"}, call("action_igmp"), _("IGMP Snooping"))

end

function action_igmp()
	local igmp_snooping
	luci.util.exec("/sbin/hrigmpsnp /proc/net/igmp_snooping /var/igmp_snooping_hr")
	igmp_snooping = luci.util.exec("cat /var/igmp_snooping_hr")
	luci.template.render("admin_status/igmp_snooping", {igmp_snooping=igmp_snooping})
end
