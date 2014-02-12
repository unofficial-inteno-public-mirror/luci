module("luci.controller.power_mgmt", package.seeall)

function index()
    local page
    local users = { "admin" }

    for k, user in pairs(users) do
        entry({user, "system", "power_mgmt"}, cbi("power_mgmt"), "Power Management", 10)
    end
end

