module("luci.controller.admin.dect", package.seeall)

function index()
	if not nixio.fs.access("/usr/bin/dectmngr") then
		return
	end

	local page

	page = entry({"admin", "services", "dect"}, template("dect_status"), _("DECT"))
	page.dependent = true

	page = entry({"admin", "services", "dect", "reg_state"}, call("reg_state"))
	page = entry({"admin", "services", "dect", "status"}, call("status"))
	page = entry({"admin", "services", "dect", "reg_start"}, call("reg_start"))
	page = entry({"admin", "services", "dect", "delete_hset"}, call("delete_hset"))
end

function reg_start()
	luci.sys.exec("/root/dect -r > /dev/null &")
	status()
end

function delete_hset(opts)
	 local handset = luci.http.formvalue("handset")
	 local rv = luci.sys.exec("/root/dect -d " .. handset)
	 
	 luci.http.write(rv)
end


function status()

	local rv = luci.sys.exec("/root/dect -j")

	luci.http.prepare_content("application/json")
	luci.http.write(rv)
end


function reg_state()

	local rv = {
		reg_state = luci.sys.exec("/usr/bin/dect -s | grep reg_state | awk '{ print $2 }'"),
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
