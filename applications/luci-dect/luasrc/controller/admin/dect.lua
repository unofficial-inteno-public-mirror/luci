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
end

function reg_start()
	luci.sys.exec("/usr/bin/dect -r > /dev/null &")
	dect_status()	
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
