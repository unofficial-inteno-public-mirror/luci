module("luci.controller.admin.dect", package.seeall)

function index()
	if not nixio.fs.access("/usr/bin/dectmngr") then
		return
	end

	local page

	page = entry({"admin", "services", "dect"}, template("dect_status"), _("DECT"))
	page.dependent = true

	page = entry({"admin", "services", "reg_start"}, call("reg_start"))
	page = entry({"admin", "services", "reg_def"}, call("reg_def"))
	page = entry({"admin", "services", "dect_status"}, call("dect_status"))
end

function reg_start()
	luci.sys.exec("/sbin/dectreg > /dev/null &")
	luci.http.redirect(luci.dispatcher.build_url("admin/services/dect"))
	return
end

function reg_def()
	luci.sys.exec("cp /etc/dect/nvs_default /etc/dect/nvs")
	luci.http.redirect(luci.dispatcher.build_url("admin/services/dect"))
	return
end

function dect_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local run = 0

	if nixio.fs.access("/var/dectisregistering") then
		run = 1
	elseif nixio.fs.access("/var/dectisregistered") then
		run = 2
	end

	local status = {
		running = run
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
