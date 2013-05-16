module("luci.controller.admin.dect", package.seeall)

function index()
	if not nixio.fs.access("/usr/bin/dectmngr") then
		return
	end

	local page

	page = entry({"admin", "services", "dect"}, template("dect_status"), _("DECT"))
	page.dependent = true

	page = entry({"admin", "services", "reg_start"}, call("reg_start"))
	page = entry({"admin", "services", "dect_status"}, call("dect_status"))
end

function reg_start()
	luci.sys.exec("/usr/bin/dect -r > /dev/null &")
end


function dect_status()

	local rv = {
		reg_state = luci.sys.exec("/usr/bin/dect -s | grep reg_state | awk '{ print $2 }'"),
		hset1 = luci.sys.exec("/usr/bin/dect -s | grep 'hset: 1'"),
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(rv)
end
