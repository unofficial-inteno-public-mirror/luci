
module("luci.controller.admin.snmp", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/snmpd") then
		return
	end

        local page

        page = node("admin", "system", "snmp")
        page.target = cbi("snmp/snmp")
        page.title  = _("SNMP")
	page.subindex = true
	page.dependent = true
	page.order = 82

	entry({"admin", "system", "snmp", "snmp"}, cbi("snmp/snmp"), "SNMP", 1)
	entry({"admin", "system", "snmp", "system"}, cbi("snmp/system"), "System", 2)
	entry({"admin", "system", "snmp", "agent"}, cbi("snmp/agent"), "Agent", 3)
	entry({"admin", "system", "snmp", "com2sec"}, cbi("snmp/com2sec"), "Com2sec", 4)
	entry({"admin", "system", "snmp", "group"}, cbi("snmp/group"), "Group", 5)
	entry({"admin", "system", "snmp", "view"}, cbi("snmp/view"), "View", 6)
	entry({"admin", "system", "snmp", "access"}, cbi("snmp/access"), "Access", 7)
	entry({"admin", "system", "snmp", "pass"}, cbi("snmp/pass"), "Pass", 8)
	entry({"admin", "system", "snmp", "exec"}, cbi("snmp/exec"), "Exec", 9)
end
