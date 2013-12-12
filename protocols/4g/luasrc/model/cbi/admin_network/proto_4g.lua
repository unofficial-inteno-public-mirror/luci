--[[
LuCI - Lua Configuration Interface

Copyright 2011-2012 Jo-Philipp Wich <xm@subsignal.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local map, section, net = ...
local ifc = net:get_interface()

local apn, pincode, username, password
local hostname, accept_ra, send_rs
local bcast, defaultroute, peerdns, dns, metric, clientid, vendorclass


service = section:taboption("general", Value, "service", translate("Service Type"))
service:value("", translate("-- Please choose --"))
service:value("ecm", translate("Ethernet Control Model"))
service:value("eem", translate("Ethernet Emulation Model"))
service:value("ncm", translate("Network Control Model"))
service:value("mbim", translate("Mobile Broadband Interface Model"))
service:value("qmi", "Qualcomm MSM Interface")

device = section:taboption("general", Value, "device", translate("Communication device"))
device.rmempty = false
device:depends("service", "ncm")
device:depends("service", "qmi")

local ttydev_suggestions = nixio.fs.glob("/dev/tty[A,U]*")
local cdcdev_suggestions = nixio.fs.glob("/dev/cdc-wdm*")

device:value("", translate("-- Please choose --"))

if ttydev_suggestions then
	local tty
	for tty in ttydev_suggestions do
		device:value(tty)
	end
end

if cdcdev_suggestions then
	local cdc
	for cdc in cdcdev_suggestions do
		device:value(cdc)
	end
end


apn = section:taboption("general", Value, "apn", translate("APN"))


pincode = section:taboption("general", Value, "pincode", translate("PIN"))


username = section:taboption("general", Value, "username", translate("PAP/CHAP username"))


password = section:taboption("general", Value, "password", translate("PAP/CHAP password"))
password.password = true


hostname = section:taboption("general", Value, "hostname",
	translate("Hostname to send when requesting DHCP"))

hostname.placeholder = luci.sys.hostname()
hostname.datatype    = "hostname"


bcast = section:taboption("advanced", Flag, "broadcast",
	translate("Use broadcast flag"),
	translate("Required for certain ISPs, e.g. Charter with DOCSIS 3"))

bcast.default = bcast.disabled


defaultroute = section:taboption("advanced", Flag, "defaultroute",
	translate("Use default gateway"),
	translate("If unchecked, no default route is configured"))

defaultroute.default = defaultroute.enabled


peerdns = section:taboption("advanced", Flag, "peerdns",
	translate("Use DNS servers advertised by peer"),
	translate("If unchecked, the advertised DNS server addresses are ignored"))

peerdns.default = peerdns.enabled


dns = section:taboption("advanced", DynamicList, "dns",
	translate("Use custom DNS servers"))

dns:depends("peerdns", "")
dns.datatype = "ipaddr"
dns.cast     = "string"


metric = section:taboption("advanced", Value, "metric",
	translate("Use gateway metric"))

metric.placeholder = "0"
metric.datatype    = "uinteger"


clientid = section:taboption("advanced", Value, "clientid",
	translate("Client ID to send when requesting DHCP"))


vendorclass = section:taboption("advanced", Value, "vendorid",
	translate("Vendor Class to send when requesting DHCP"))


luci.tools.proto.opt_macaddr(section, ifc, translate("Override MAC address"))


mtu = section:taboption("advanced", Value, "mtu", translate("Override MTU"))
mtu.placeholder = "1500"
mtu.datatype    = "max(9200)"
