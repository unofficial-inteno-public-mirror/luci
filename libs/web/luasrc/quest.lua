module("luci.quest", package.seeall)

local bus = require "ubus"

function router_static_sysinfo()
	local _ubus
	local _ubuscache = { }
	local rv = { }

	_ubus = bus.connect()
	_ubuscache["system"] = _ubus:call("router", "quest", { info = "system" })
	_ubus:close()

	if not _ubuscache["system"] then
		return rv
	end

	rv = {
		hostname = _ubuscache["system"]["name"],
		hardware = _ubuscache["system"]["hardware"],
		model = _ubuscache["system"]["model"],
		iopversion = _ubuscache["system"]["firmware"],
		brcmversion = _ubuscache["system"]["brcmver"],
		socmodel = _ubuscache["system"]["socmod"],
		socrevision = _ubuscache["system"]["socrev"],
		cfeversion = _ubuscache["system"]["cfever"],
		kernel = _ubuscache["system"]["kernel"]
	}

	return rv
end

function router_dynamic_sysinfo(field)
	local _ubus
	local _ubuscache = { }

	_ubus = bus.connect()
	_ubuscache["system"] = _ubus:call("router", "quest", { info = "system" })
	_ubus:close()

	if not _ubuscache["system"] then
		return 0
	end

	return _ubuscache["system"][field]
end

processes = router_dynamic_sysinfo("procs")
cpuload = router_dynamic_sysinfo("cpu_per")
uptime = router_dynamic_sysinfo("uptime")

function router_keys()
	local _ubus
	local _ubuscache = { }
	local rv = { }

	_ubus = bus.connect()
	_ubuscache["keys"] = _ubus:call("router", "quest", { info = "keys" })
	_ubus:close()

	if not _ubuscache["keys"] then
		return rv
	end

	rv = {
		authkey = _ubuscache["keys"]["auth"],
		deskey = _ubuscache["keys"]["des"],
		wpakey = _ubuscache["keys"]["wpa"]
	}

	return rv
end

function router_specs()
	local _ubus
	local _ubuscache = { }
	local rv = { }

	_ubus = bus.connect()
	_ubuscache["specs"] = _ubus:call("router", "quest", { info = "specs" })
	_ubus:close()

	if not _ubuscache["specs"] then
		return rv
	end

	rv = {
		haswifi = _ubuscache["specs"]["wifi"],
		hasadsl = _ubuscache["specs"]["adsl"],
		hasvdsl = _ubuscache["specs"]["vdsl"],
		hasvoice = _ubuscache["specs"]["voice"],
		voice_ports = _ubuscache["specs"]["voice_ports"],
		eth_ports = _ubuscache["specs"]["eth_ports"]
	}

	return rv
end

function router_memory_info()
	local _ubus
	local _ubuscache = { }
	local rv = { }

	_ubus = bus.connect()
	_ubuscache["memory"] = _ubus:call("router", "quest", { info = "memory" })
	_ubus:close()

	if not _ubuscache["memory"] then
		return rv
	end

	rv = {
		memtotal = _ubuscache["memory"]["total"],
		memused = _ubuscache["memory"]["used"],
		memfree = _ubuscache["memory"]["free"],
		memshared = _ubuscache["memory"]["shared"],
		membuffers = _ubuscache["memory"]["buffers"]
	}

	return rv
end

