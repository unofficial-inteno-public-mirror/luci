--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.upnp", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/upnpd") then
		return
	end

	local users = { "admin", "support", "user" }
	local page

	for k, user in pairs(users) do
		page = entry({user, "services", "upnp"}, cbi("upnp/upnp"), _("UPNP"))
		page.dependent = true

		entry({user, "services", "upnp", "status"}, call("act_status")).leaf = true
		entry({user, "services", "upnp", "delete"}, call("act_delete")).leaf = true
	end
end

function act_status()
	local ipt = io.popen("iptables --line-numbers -t nat -xnvL MINIUPNPD")
	if ipt then
		local fwd = { }
		while true do
			local ln = ipt:read("*l")
			if not ln then
				break
			elseif ln:match("^%d+") then
				local num, proto, extport, intaddr, intport =
					ln:match("^(%d+).-([a-z]+).-dpt:(%d+) to:(%S-):(%d+)")

				if num and proto and extport and intaddr and intport then
					num     = tonumber(num)
					extport = tonumber(extport)
					intport = tonumber(intport)

					fwd[#fwd+1] = {
						num     = num,
						proto   = proto:upper(),
						extport = extport,
						intaddr = intaddr,
						intport = intport
					}
				end
			end
		end

		ipt:close()

		luci.http.prepare_content("application/json")
		luci.http.write_json(fwd)
	end
end

function act_delete(num)
	local idx = tonumber(num)
	local uci = luci.model.uci.cursor()

	if idx and idx > 0 then
		luci.sys.call("iptables -t filter -D MINIUPNPD %d 2>/dev/null" % idx)
		luci.sys.call("iptables -t nat -D MINIUPNPD %d 2>/dev/null" % idx)

		local lease_file = uci:get("upnpd", "config", "upnp_lease_file")
		if lease_file and nixio.fs.access(lease_file) then
			luci.sys.call("sed -i -e '%dd' %q" %{ idx, lease_file })
		end

		luci.http.status(200, "OK")
		return
	end

	luci.http.status(400, "Bad request")
end
