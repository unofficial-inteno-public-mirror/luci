module("luci.controller.support.dect", package.seeall)

function index()
	if not nixio.fs.access("/usr/bin/dectmngr") then
		return
	end

	local page

	page = entry({"support", "services", "dect"}, template("dect_status"), _("DECT"))
	page.dependent = true

	page = entry({"support", "services", "reg_start"}, call("reg_start"))
	page = entry({"support", "services", "reg_def"}, call("reg_def"))
	page = entry({"support", "services", "dect_status"}, call("dect_status"))
end

function reg_start()
	luci.sys.exec("/sbin/dectreg > /dev/null &")
	luci.http.redirect(luci.dispatcher.build_url("support/services/dect"))
	return
end

function reg_def()
	luci.sys.exec("cp /etc/dect/nvs_default /etc/dect/nvs")
	luci.http.redirect(luci.dispatcher.build_url("support/services/dect"))
	return
end

function dect_status()
	local sys  = require "luci.sys"
	local uci  = require "luci.model.uci".cursor()
	local run = 0

	if nixio.fs.access("/var/dectisregistering") then
		run = 1
	end

	local status = {
		running = run
	}

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
