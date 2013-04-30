
module("luci.controller.admin.snmp", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/snmpd") then
		return
	end

	local page

	page = entry({"admin", "system", "snmp"}, cbi("admin_system/snmp"), _("SNMP"))
	page.order = 82
	page.dependent = true
end
