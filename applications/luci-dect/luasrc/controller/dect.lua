module("luci.controller.dect", package.seeall)

function index()
	if not nixio.fs.access("/usr/sbin/dectmngr2") then
		return
	end

	local users = { "admin", "support", "user" }
	local page

	for k, user in pairs(users) do

		page = node(user, "services", "dect")
		page.target = template("dect_status")
		page.title  = _("DECT")
		page.subindex = true

		entry({user, "services", "dect", "main"}, template("dect_status"), "Status", 1)
		entry({user, "services", "dect", "config"}, cbi("admin_status/dect"), "Configuration", 2)

		page = entry({user, "services", "dect", "status"}, call("status"))
		page = entry({user, "services", "dect", "reg_start"}, call("reg_start"))
		page = entry({user, "services", "dect", "delete_hset"}, call("delete_hset"))
		page = entry({user, "services", "dect", "ping_hset"}, call("ping_hset"))
		--page = entry({user, "services", "dect", "switch_plug"}, call("switch_plug"))
	end
end

function reg_start()
	luci.sys.exec("ubus -t 1 call dect state \"{'registration':'on'}\"")
	status()
end

function delete_hset(opts)
	 local handset = tonumber(luci.http.formvalue("handset"))
	 local rv = luci.sys.exec("ubus -t 1 call dect call \"{'terminal':%d, 'release':%d}\"" % {handset, handset-1})
	 
	 luci.http.write(rv)
end


function ping_hset(opts)
	 local handset = tonumber(luci.http.formvalue("handset"))
	 local rv = luci.sys.exec("ubus -t 1 call dect call \"{'terminal':%d, 'add':%d}\"" % {handset, handset-1})
	 
	 luci.http.write(rv)
end


function switch_plug(opts)
	 local handset = luci.http.formvalue("plug")
	 local rv = luci.sys.exec("/usr/bin/dect -z " .. handset)
	 
	 luci.http.write(rv)
end


function status()
	local rv = luci.sys.exec("ubus -t 1 call dect status | tr '}' ',' > /tmp/dect_status; ubus -t 1 call dect handset \"{'list':''}\" | tail -n +2 >> /tmp/dect_status; cat /tmp/dect_status")

	luci.http.prepare_content("application/json")
	luci.http.write(rv)
end
