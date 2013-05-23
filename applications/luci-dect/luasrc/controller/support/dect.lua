module("luci.controller.support.dect", package.seeall)

function index()
	if not nixio.fs.access("/usr/bin/dectmngr") then
		return
	end

	local page

	page = entry({"support", "services", "dect"}, template("dect_status"), _("DECT"))
	page.dependent = true

	page = entry({"support", "services", "dect", "status"}, call("status"))
	page = entry({"support", "services", "dect", "reg_start"}, call("reg_start"))
	page = entry({"support", "services", "dect", "delete_hset"}, call("delete_hset"))
	page = entry({"support", "services", "dect", "ping_hset"}, call("ping_hset"))
end

function reg_start()
	luci.sys.exec("/usr/bin/dect -r > /dev/null &")
	status()
end

function delete_hset(opts)
	 local handset = luci.http.formvalue("handset")
	 local rv = luci.sys.exec("/usr/bin/dect -d " .. handset)
	 
	 luci.http.write(rv)
end


function ping_hset(opts)
	 local handset = luci.http.formvalue("handset")
	 local rv = luci.sys.exec("/usr/bin/dect -p " .. handset)
	 
	 luci.http.write(rv)
end


function status()

	local rv = luci.sys.exec("/usr/bin/dect -j")

	luci.http.prepare_content("application/json")
	luci.http.write(rv)
end


