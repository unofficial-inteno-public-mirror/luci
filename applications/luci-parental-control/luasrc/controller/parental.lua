module("luci.controller.parental", package.seeall)

function index()
	local users = { "admin", "support", "user" }
	local page

	for k, user in pairs(users) do
		entry({user, "network", "parental"}, cbi("parental"), "Parental Control").order=65
	end
end

