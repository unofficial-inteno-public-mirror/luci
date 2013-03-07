local tonumber = tonumber
local require = require
local sys = require "luci.sys"
local uci = require "luci.model.uci"
local utl = require "luci.util"
local nfs = require "nixio.fs"

module "luci.model.ports"

_uci_real  = cursor or _uci_real or uci.cursor()

function init(cursor)
	return _M
end

function status_eth(self, port)
	local eth = tonumber(sys.exec("cat /sys/class/net/%s/carrier" %port))
	if eth == 1 then
		return "up"
	elseif eth == 0 then
		return "down"
	else
		return "none"
	end
end

function status_dsl(self)
	local vdsl = tonumber(sys.exec("cat /var/state/layer2_interface | grep 'vdsl' | grep -c 'up'"))
	local adsl = tonumber(sys.exec("cat /var/state/layer2_interface | grep 'adsl' | grep -c 'up'"))

	if vdsl > 0 then
		return "vdsl"
	elseif adsl > 0 then
		return "adsl"
	else
		return "none"
	end
end

function status_usb(self)
	local usb = tonumber(sys.exec("[ -d /sys/bus/usb/devices/1-1 ] || [ -d /sys/bus/usb/devices/1-2 ] || [ -d /sys/bus/usb/devices/2-1 ] || [ -d /sys/bus/usb/devices/2-2 ] && echo 1"))
	return usb
end

function port_type(self, port)
	return sys.exec(". /lib/network/config.sh && interfacename %s" %port)
end

function port_speed(self, port)
	return sys.exec(". /lib/network/config.sh && interfacespeed %s" %port)
end

function eth_type(self, port)
	local wan = tonumber(sys.exec("uci get layer2_interface_ethernet.Wan.baseifname | awk -F'eth' '{print$2}'"))
	if port == wan then
		return "wan"
	else
		return ""
	end
end

function Wname (self, ifname)
	local wanif = ifname
	if ifname:match("br-") then
		for vif in utl.execi("uci get network.%s.ifname | tr ' ' '\n'" %ifname:sub(4)) do
			if vif:match("^atm%d.1$") or vif:match("^ptm%d.1$") or vif:match("^eth%d.1$") then
				local path = "/sys/devices/virtual/net/%s/statistics/rx_packets" %vif
				if nfs.access(path) and tonumber(sys.exec("cat %s" %path)) > 0 then
					wanif = vif
					break
				end
			end
		end
	end
	return wanif
end

function l2name (self, ifname)
	local l2name = ""
	if ifname:match("^atm%d.1$")  then
		_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
		function(s)
			if ifname == s.ifname then
				l2name = s.name
			end
		end)
	elseif ifname:match("^ptm%d.1$") then
		_uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
		function(s)
			if ifname == s.ifname then
				l2name = s.name
			end
		end)
	elseif ifname:match("^eth%d.1$") then
		_uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
		function(s)
			if ifname == s.ifname then
				l2name = s.name
			end
		end)
	elseif ifname:match("br-") then
		local vif = self:Wname(ifname)
		if vif:match("^atm%d.1$")  then
			_uci_real:foreach("layer2_interface_adsl", "atm_bridge",
			function(s)
				if vif == s.ifname then
					l2name = s.name
				end
			end)
		elseif vif:match("^ptm%d.1$") then
			_uci_real:foreach("layer2_interface_vdsl", "vdsl_interface",
			function(s)
				if vif == s.ifname then
					l2name = s.name
				end
			end)
		elseif vif:match("^eth%d.1$") then
			_uci_real:foreach("layer2_interface_ethernet", "ethernet_interface",
			function(s)
				if vif == s.ifname then
					l2name = s.name
				end
			end)
		end
	end
	return l2name
end

function dslrate(self, w) -- DSL Rate
	if w == "down" then
		return sys.exec("xdslctl info --stats | grep 'Bearer:' | awk -F'Downstream' '{print$2}' | awk -F' ' '{print$3}'")
	elseif w == "up" then
		return sys.exec("xdslctl info --stats | grep 'Bearer:' | awk -F'Upstream rate =' '{print$2}' | awk -F' ' '{print$1}'")
	end
end
