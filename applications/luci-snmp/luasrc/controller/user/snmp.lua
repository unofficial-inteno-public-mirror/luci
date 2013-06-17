
module("luci.controller.user.snmp", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/snmpd") then
		return
	end

        local page

        page = node("user", "system", "snmp")
        page.target = cbi("snmp/system")
        page.title  = _("SNMP")
	page.subindex = true
	page.dependent = true
	page.order = 82

	entry({"user", "system", "snmp", "system"}, cbi("snmp/system"), "System", 1)
	entry({"user", "system", "snmp", "agent"}, cbi("snmp/agent"), "Agent", 2)
	entry({"user", "system", "snmp", "com2sec"}, cbi("snmp/com2sec"), "Com2sec", 3)
	entry({"user", "system", "snmp", "group"}, cbi("snmp/group"), "Group", 4)
	entry({"user", "system", "snmp", "view"}, cbi("snmp/view"), "View", 5)
	entry({"user", "system", "snmp", "access"}, cbi("snmp/access"), "Access", 6)
	entry({"user", "system", "snmp", "pass"}, cbi("snmp/pass"), "Pass", 7)
	entry({"user", "system", "snmp", "exec"}, cbi("snmp/exec"), "Exec", 8)
end
