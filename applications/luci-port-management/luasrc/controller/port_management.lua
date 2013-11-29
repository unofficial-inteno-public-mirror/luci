module("luci.controller.port_management", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ports") then
		return
	end

	local users = { "admin", "support", "user" }
	local page

	for k, user in pairs(users) do
		page = entry({user, "network", "port_management"}, cbi("port_management"), _("Port Management"), 12)
		page.dependent = true
	end
end
