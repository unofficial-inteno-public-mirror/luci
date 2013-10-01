module("luci.controller.iup", package.seeall)

function index()
        entry({"admin", "system", "iup"}, cbi("provisioning/iup"), "Provisioning", 81)
        if nixio.fs.access("/etc/config/cwmp") then
		entry({"admin", "system", "iup", "iup"}, cbi("provisioning/iup"), "IUP", 1)
		entry({"admin", "system", "iup", "cwmp"}, cbi("provisioning/cwmp"), "TR-069", 2)
        end             
end
