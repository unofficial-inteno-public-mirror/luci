--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: wifi.lua 9558 2012-12-18 13:58:22Z jow $
]]--

local wa = require "luci.tools.webadmin"
local nw = require "luci.model.network"
local ut = require "luci.util"
local nt = require "luci.sys".net
local fs = require "nixio.fs"

arg[1] = arg[1] or ""

m = Map("wireless", "",
	translate("The <em>Device Configuration</em> section covers settings which are shared among all defined wireless networks (if the radio hardware is multi-SSID capable). " ..
		"Per network settings like encryption or operation mode are grouped in the <em>Interface Configuration</em>."))
		

m:chain("network")
m:chain("firewall")

local ifsection

function m.on_commit(map)
	local wnet = nw:get_wifinet(arg[1])
	if ifsection and wnet then
		ifsection.section = wnet.sid
		m.title = luci.util.pcdata(wnet:get_i18n())
	end
end

nw.init(m.uci)

local wnet = nw:get_wifinet(arg[1])
local wdev = wnet and wnet:get_device()

-- redirect to overview page if network does not exist anymore (e.g. after a revert)
if not wnet or not wdev then
	luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless"))
	return
end

-- wireless toggle was requested, commit and reload page
function m.parse(map)
	if m:formvalue("cbid.wireless.%s.__toggle" % wdev:name()) then
		if wdev:get("disabled") == "1" or wnet:get("disabled") == "1" then
			wnet:set("disabled", nil)
		else
			wnet:set("disabled", "1")
		end
		wdev:set("disabled", nil)

		nw:commit("wireless")
		luci.sys.call("(env -i /sbin/wifi down; env -i /sbin/wifi up) >/dev/null 2>/dev/null")

		luci.http.redirect(luci.dispatcher.build_url("admin/network/wireless", arg[1]))
		return
	end
	Map.parse(map)
end

m.title = luci.util.pcdata(wnet:get_i18n())


local function txpower_list(iw)
	local list = iw.txpwrlist or { }
	local off  = tonumber(iw.txpower_offset) or 0
	local new  = { }
	local prev = -1
	local _, val
	for _, val in ipairs(list) do
		local dbm = val.dbm + off
		local mw  = math.floor(10 ^ (dbm / 10))
		if mw ~= prev then
			prev = mw
			new[#new+1] = {
				display_dbm = dbm,
				display_mw  = mw,
				driver_dbm  = val.dbm,
				driver_mw   = val.mw
			}
		end
	end
	return new
end

local function txpower_current(pwr, list)
	pwr = tonumber(pwr)
	if pwr ~= nil then
		local _, item
		for _, item in ipairs(list) do
			if item.driver_dbm >= pwr then
				return item.driver_dbm
			end
		end
	end
	return (list[#list] and list[#list].driver_dbm) or pwr or 0
end

local iw = luci.sys.wifi.getiwinfo(arg[1])
local hw_modes      = iw.hwmodelist or { }
local tx_power_list = txpower_list(iw)
local tx_power_cur  = txpower_current(wdev:get("txpower"), tx_power_list)

s = m:section(NamedSection, wdev:name(), "wifi-device", translate("Device Configuration"))
s.addremove = false

s:tab("general", translate("General Setup"))
s:tab("macfilter", translate("MAC-Filter"))
s:tab("advanced", translate("Advanced Settings"))
s:tab("antenna", translate("Antenna Selection"))
--s:tab("bridge", translate("Wireless Bridge"))

--[[
back = s:option(DummyValue, "_overview", translate("Overview"))
back.value = ""
back.titleref = luci.dispatcher.build_url("admin", "network", "wireless")
]]

st = s:taboption("general", DummyValue, "__status", translate("Status"))
st.template = "admin_network/wifi_status"
st.ifname   = arg[1]

en = s:taboption("general", Button, "__toggle")

if wdev:get("disabled") == "1" or wnet:get("disabled") == "1" then
	en.title      = translate("%s is disabled" %(wnet:ssid() or wnet:ifname() or "Wireless network"))
	en.inputtitle = translate("Enable")
	en.inputstyle = "apply"
else
	en.title      = translate("%s is enabled" %(wnet:ssid() or wnet:ifname() or "Wireless network"))
	en.inputtitle = translate("Disable")
	en.inputstyle = "reset"
end


local hwtype = wdev:get("type")
local htcaps = wdev:get("ht_capab") and true or false

-- NanoFoo
local nsantenna = wdev:get("antenna")

-- Check whether there is a client interface on the same radio,
-- if yes, lock the channel choice as the station will dicatate the freq
local has_sta = nil
local _, net
for _, net in ipairs(wdev:get_wifinets()) do
	if net:mode() == "sta" and net:id() ~= wnet:id() then
		has_sta = net
		break
	end
end

--[[
if has_sta then
	ch = s:taboption("advanced", DummyValue, "choice", translate("Channel"))
	ch.value = translatef("Locked to channel %d used by %s",
		has_sta:channel(), has_sta:shortname())
else
	ch = s:taboption("advanced", ListValue, "channel", translate("Channel"))
	ch:value("auto", translate("Auto"))
	ch:value("1", translate("1"))
	ch:value("2", translate("2"))
	ch:value("3", translate("3"))
	ch:value("4", translate("4"))
	ch:value("5", translate("5"))
	ch:value("6", translate("6"))
	ch:value("7", translate("7"))
	ch:value("8", translate("8"))
	ch:value("9", translate("9"))
	ch:value("10", translate("10"))
	ch:value("11", translate("11"))
	ch:value("12", translate("12"))
	ch:value("13", translate("13"))
--	for _, f in ipairs(iw and iw.freqlist or luci.sys.wifi.channels()) do
--		if not f.restricted then
--			ch:value(f.channel, "%i (%.3f GHz)" %{ f.channel, f.mhz / 1000 })
--		end
--	end
end
]]

------------------- Broadcom Device ------------------

if hwtype == "broadcom" then

	country = s:taboption("general", ListValue, "country", translate("Country"))
	country:value("ALL", "ALL")
	country:value("DK", "DENMARK")
	country:value("EE", "ESTONIA")
	country:value("FI", "FINLAND")
	country:value("NO", "NORWAY")
	country:value("SE", "SWEDEN")
	country:value("US", "UNITED STATES")

	s:taboption("general", Value, "maxassoc", translate("Connection Limit"))

	band = s:taboption("advanced", ListValue, "band", translate("Band"))

	bnd = wdev:bands()
	if bnd:match("b") then band:value("b", translate("2.4GHz")) end
	if bnd:match("a") then band:value("a", translate("5GHz")) end

	mode = s:taboption("advanced", ListValue, "hwmode", translate("Mode"))
	mode:value("auto", "Auto")
	mode:value("11b", "802.11b", {band="b"})
	mode:value("11bg", "802.11b+g", {band="b"})
	mode:value("11g", "802.11g", {band="b"})
	mode:value("11gst", "802.11g + Turbo", {band="b"})
	mode:value("11lrs", "802.11 LRS", {band="b"})
	mode:value("11n", "802.11n")
	if wdev:hwmodes().ac then 
		mode:value("11ac", "802.11ac", {band="a"})
	end

	bw = s:taboption("advanced", ListValue, "bandwidth", translate("Bandwidth"))
	bw:depends("hwmode", "auto")
	bw:depends("hwmode", "11n")
	bw:depends("hwmode", "11ac")
	bw:value("20", "20MHz")
	bw:value("40", "40Mhz")
	bw:value("80", "80Mhz", {hwmode="11ac"})

	ch = s:taboption("advanced", ListValue, "channel", translate("Channel"))
	ch:value("auto", translate("Auto"))

	btn = s:taboption("advanced", Button, "btn" , translate("Update Channel List"))
	function btn.write(self)
		for chn in wdev:channels(wdev:get("country"), wdev:get("band"), wdev:get("bandwidth")) do
			ch:value(chn, chn)
		end
	end

	timer = s:taboption("advanced", Value, "scantimer", translate("Auto Channel Timer"), "min")
	timer:depends("channel", "auto")
	timer.default = 10

	rifs = s:taboption("advanced", ListValue, "rifs", translate("RIFS"))
	rifs:depends("hwmode", "auto")
	rifs:depends("hwmode", "11n")
	rifs:value("0", "Off")	
	rifs:value("1", "On")

	rifsad = s:taboption("advanced", ListValue, "rifs_advert", translate("RIFS Advertisement"))
	rifs:depends("hwmode", "auto")
	rifs:depends("hwmode", "11n")
	rifsad:value("0", "Off")	
	rifsad:value("-1", "Auto")

	obss = s:taboption("advanced", ListValue, "obss_coex", translate("OBSS Co-Existence"))
	obss:depends("bandwidth", "40")
	obss:value("1", "Enable")

	nrate = s:taboption("advanced", ListValue, "nrate", translate("Rate"))
	nrate:depends({hwmode="11n"})
	nrate:value("auto", "Auto")	
	nrate:value("-r 1", "Legacy 1 Mbps")
	nrate:value("-r 2", "Legacy 2 Mbps")
	nrate:value("-r 5.5", "Legacy 5.5 Mbps")
	nrate:value("-r 6", "Legacy 6 Mbps")
	nrate:value("-r 9", "Legacy 9 Mbps")
	nrate:value("-r 11", "Legacy 11 Mbps")
	nrate:value("-r 12", "Legacy 12 Mbps")
	nrate:value("-r 18", "Legacy 18 Mbps")
	nrate:value("-r 24", "Legacy 24 Mbps")
	nrate:value("-r 36", "Legacy 36 Mbps")
	nrate:value("-r 48", "Legacy 48 Mbps")
	nrate:value("-r 54", "Legacy 54 Mbps")
	nrate:value("-m 0", "MCS 0: 6.5 Mbps", {bandwidth="20"})
	nrate:value("-m 1", "MCS 1: 13 Mbps", {bandwidth="20"})
	nrate:value("-m 2", "MCS 2: 19.5 Mbps", {bandwidth="20"})
	nrate:value("-m 3", "MCS 3: 26 Mbps", {bandwidth="20"})
	nrate:value("-m 4", "MCS 4: 39 Mbps", {bandwidth="20"})
	nrate:value("-m 5", "MCS 5: 52 Mbps", {bandwidth="20"})
	nrate:value("-m 6", "MCS 6: 58.5 Mbps", {bandwidth="20"})
	nrate:value("-m 7", "MCS 7: 65 Mbps", {bandwidth="20"})
	nrate:value("-m 8", "MCS 8: 13 Mbps", {bandwidth="20"})
	nrate:value("-m 9", "MCS 9: 26 Mbps", {bandwidth="20"})
	nrate:value("-m 10", "MCS 10: 39 Mbps", {bandwidth="20"})
	nrate:value("-m 11", "MCS 11: 52 Mbps", {bandwidth="20"})
	nrate:value("-m 12", "MCS 12: 78 Mbps", {bandwidth="20"})
	nrate:value("-m 13", "MCS 13: 104 Mbps", {bandwidth="20"})
	nrate:value("-m 14", "MCS 14: 117 Mbps", {bandwidth="20"})
	nrate:value("-m 15", "MCS 15: 130 Mbps", {bandwidth="20"})
	nrate:value("-m 0 ", "MCS 0: 13.5 Mbps", {bandwidth="40"})
	nrate:value("-m 1 ", "MCS 1: 27 Mbps", {bandwidth="40"})
	nrate:value("-m 2 ", "MCS 2: 40.5 Mbps", {bandwidth="40"})
	nrate:value("-m 3 ", "MCS 3: 54 Mbps", {bandwidth="40"})
	nrate:value("-m 4 ", "MCS 4: 81 Mbps", {bandwidth="40"})
	nrate:value("-m 5 ", "MCS 5: 108 Mbps", {bandwidth="40"})
	nrate:value("-m 6 ", "MCS 6: 121.5 Mbps", {bandwidth="40"})
	nrate:value("-m 7 ", "MCS 7: 135 Mbps", {bandwidth="40"})
	nrate:value("-m 8 ", "MCS 8: 27 Mbps", {bandwidth="40"})
	nrate:value("-m 9 ", "MCS 9: 54 Mbps", {bandwidth="40"})
	nrate:value("-m 10 ", "MCS 10: 81 Mbps", {bandwidth="40"})
	nrate:value("-m 11 ", "MCS 11: 108 Mbps", {bandwidth="40"})
	nrate:value("-m 12 ", "MCS 12: 162 Mbps", {bandwidth="40"})
	nrate:value("-m 13 ", "MCS 13: 216 Mbps", {bandwidth="40"})
	nrate:value("-m 14 ", "MCS 14: 243 Mbps", {bandwidth="40"})
	nrate:value("-m 15 ", "MCS 15: 270 Mbps", {bandwidth="40"})
	nrate:value("-m 32 ", "MCS 32: 6 Mbps", {bandwidth="40"})

	grate = s:taboption("advanced", ListValue, "grate", translate("Rate"))
	grate:depends("hwmode", "11bg")
	grate:depends("hwmode", "11g")
	grate:depends("hwmode", "11gst")
	grate:depends("hwmode", "11lrs")
	grate:value("auto", "Auto")	
	grate:value("1", "1 Mbps")
	grate:value("2", "2 Mbps")
	grate:value("5.5", "5.5 Mbps")
	grate:value("6", "6 Mbps")
	grate:value("9", "9 Mbps")
	grate:value("11", "11 Mbps")
	grate:value("12", "12 Mbps")
	grate:value("18", "18 Mbps")
	grate:value("24", "24 Mbps")
	grate:value("36", "36 Mbps")
	grate:value("48", "48 Mbps")
	grate:value("54", "54 Mbps")

	brate = s:taboption("advanced", ListValue, "brate", translate("Rate"))
	brate:depends("hwmode", "11b")
	brate:value("auto", "Auto")	
	brate:value("1", "1 Mbps")
	brate:value("2", "2 Mbps")
	brate:value("5.5", "5.5 Mbps")
	brate:value("11", "11 Mbps")

	rateset = s:taboption("advanced", Value, "rateset", translate("Basic Rate"))
	rateset:value("default", "Default")	
	rateset:value("all", "All")

	rxcps = s:taboption("advanced", ListValue, "rxchainps", translate("RX Chain Power Save"))
	rxcps:value("0", "Disable")	
	rxcps:value("1", "Enable")

	rxcpsqt = s:taboption("advanced", Value, "rxchainps_qt", translate("RX Chain Power Save Quite Time"))
	rxcpsqt.default = 10
	rxcpspps = s:taboption("advanced", Value, "rxchainps_pps", translate("RX Chain Power Save PPS"))
	rxcpspps.default = 10

	s:taboption("advanced", Flag, "frameburst", translate("Frame Bursting"))

	--s:taboption("advanced", Value, "distance", translate("Distance Optimization"))
	--s:option(Value, "slottime", translate("Slot time"))

	frag = s:taboption("advanced", Value, "frag", translate("Fragmentation Threshold"))
	frag.default = 2346
	rts = s:taboption("advanced", Value, "rts", translate("RTS Threshold"))
	rts.default = 2347
	dtim = s:taboption("advanced", Value, "dtim_period", translate("DTIM Interval"))
	dtim.default = 1
	bcn = s:taboption("advanced", Value, "beacon_int", translate("Beacon Interval"))
	bcn.default = 100
	
	sm = s:taboption("advanced", ListValue, "doth", "802.11h Spectrum Management Mode")
	sm:value("0", "Off")	
	sm:value("1", "Loose interpretation of 11h spec")
	sm:value("2", "Strict interpretation of 11h spec")
	sm:value("3", "Disable 11h and enable 11d")

	pwr = s:taboption("advanced", ListValue, "txpower", translate("Transmit Power"))
	pwr:value("10", "10%")
	pwr:value("20", "20%")
	pwr:value("30", "30%")
	pwr:value("40", "40%")
	pwr:value("50", "50%")
	pwr:value("60", "60%")
	pwr:value("70", "70%")
	pwr:value("80", "80%")
	pwr:value("90", "90%")
	pwr:value("100", "100%")

	wm = s:taboption("advanced", ListValue, "wmm", translate("WMM Mode"))
	wm:value("-1", "Auto")	
	wm:value("1", "Enable")
	wm:value("0", "Disable")
	wn = s:taboption("advanced", ListValue, "wmm_noack", translate("WMM No Acknowledgement"))
	wn:depends({wmm="1"})
	wn:depends({wmm="-1"})
	wn:value("1", "Enable")
	wn:value("0", "Disable")
	wa = s:taboption("advanced", ListValue, "wmm_apsd", translate("WMM APSD"))
	wa:depends({wmm="1"})
	wa:depends({wmm="-1"})
	wa:value("1", "Enable")
	wa:value("0", "Disable")

	ant1 = s:taboption("antenna", ListValue, "txantenna", translate("Transmitter Antenna"))
	ant1.widget = "radio"
	ant1:depends("diversity", "")
	ant1:value("3", translate("auto"))
	ant1:value("0", translate("Antenna 1"))
	ant1:value("1", translate("Antenna 2"))
	ant1.default = "3"

	ant2 = s:taboption("antenna", ListValue, "rxantenna", translate("Receiver Antenna"))
	ant2.widget = "radio"
	ant2:depends("diversity", "")
	ant2:value("3", translate("auto"))
	ant2:value("0", translate("Antenna 1"))
	ant2:value("1", translate("Antenna 2"))
	ant2.default = "3"

--	wdsmode = s:taboption("bridge", ListValue, "wdsmode", translate("WDS Mode"), "Selecting Automatic WDS mode will dynamically grant WDS membership to anyone")
--	wdsmode:value("0", translate("Manual"))
--	wdsmode:value("1", translate("Automatic"))
--	wdslist = s:taboption("bridge", DynamicList, "wdslist", translate("WDS Connection List"))
--	wdslist:depends({wdsmode="0"})
--	wdstimo = s:taboption("bridge", Value, "wdstimo", translate("WDS Link Detection Timeout"), "min")
end


----------------------- Interface -----------------------

s = m:section(NamedSection, wnet.sid, "wifi-iface", translate("Interface Configuration"))
ifsection = s
s.addremove = false
s.anonymous = true
s.defaults.device = wdev:name()

s:tab("general", translate("General Setup"))
s:tab("encryption", translate("Wireless Security"))
s:tab("macfilter", translate("MAC-Filter"))
s:tab("advanced", translate("Advanced Settings"))

s:taboption("general", Value, "ssid", translate("<abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))

mode = s:taboption("general", ListValue, "mode", translate("Mode"))
mode.override_values = true
mode:value("ap", translate("Access Point"))
--mode:value("sta", translate("Client"))
--mode:value("adhoc", translate("Ad-Hoc"))

bssid = s:taboption("general", Value, "bssid", translate("<abbr title=\"Basic Service Set Identifier\">BSSID</abbr>"))

network = s:taboption("general", Value, "network", translate("Network"),
	translate("Choose the network(s) you want to attach to this wireless interface or " ..
		"fill out the <em>create</em> field to define a new network."))

network.rmempty = true
network.template = "cbi/network_netlist"
network.widget = "checkbox"
network.novirtual = true

function network.write(self, section, value)
	local i = nw:get_interface(section)
	if i then
		if value == '-' then
			value = m:formvalue(self:cbid(section) .. ".newnet")
			if value and #value > 0 then
				local n = nw:add_network(value, {proto="none"})
				if n then n:add_interface(i) end
			else
				local n = i:get_network()
				if n then n:del_interface(i) end
			end
		else
			local v
			for _, v in ipairs(i:get_networks()) do
				v:del_interface(i)
			end
			for v in ut.imatch(value) do
				local n = nw:get_network(v)
				if n then
					if not n:is_empty() then
						n:set("type", "bridge")
					end
					n:add_interface(i)
				end
			end
		end
	end
end


-------------------- Broadcom Interface ----------------------

if hwtype == "broadcom" then

	if fs.access("/sbin/myfid") then
		anyfi_srv = s:taboption("general", Flag, "anyfi_enabled", translate("Anyfi.net remote access"),
		                         translate("Allow remote access to this Wi-Fi network."))
		anyfi_srv:depends({mode="ap", encryption="psk"})
		anyfi_srv:depends({mode="ap", encryption="psk2"})
		anyfi_srv:depends({mode="ap", encryption="pskmixedpsk2"})
		anyfi_srv.rmempty = false
		anyfi_srv.default = "0"

		function anyfi_srv.write(self, section, value)
			if value == "1"  then
				wdev:set("anyfi_enabled", "1")
			else
				local dev_anyfi_enabled = "0"
				local old_enabled = wdev:get("anyfi_enabled")
				for _, net in ipairs(wdev:get_wifinets()) do
			    	      if net:name() == wnet:name() then
			       	          if value == "1" then
			       	  	      dev_anyfi_enabled = "1"
					  end
				      elseif net:get("anyfi_enabled") == "1" then
				         dev_anyfi_enabled = "1"
				      end
				end
				if dev_anyfi_enabled ~= old_enabled then
					wdev:set("anyfi_enabled", dev_anyfi_enabled)
				end
			end
			self.map:set(section, "anyfi_enabled", value)
		end
	end

	--mode:value("wds", translate("WDS"))
	--mode:value("monitor", translate("Monitor"))

	hidden = s:taboption("general", Flag, "hidden", translate("Hide <abbr title=\"Extended Service Set Identifier\">ESSID</abbr>"))
	hidden:depends({mode="ap"})
	hidden:depends({mode="adhoc"})
	hidden:depends({mode="wds"})

	s:taboption("general", Value, "bss_max", translate("Maximum Client"))

	isolate = s:taboption("advanced", Flag, "isolate", translate("Separate Clients"), translate("Prevents client-to-client communication"))
	isolate:depends({mode="ap"})

	s:taboption("advanced", Flag, "wmf_bss_enable", "Enable Wireless Multicast Forwarding (WMF)")
	s:taboption("advanced", Flag, "wmm_bss_disable", translate("Disable WMM Advertise"))

	mf = s:taboption("macfilter", ListValue, "macfilter", translate("MAC-Address Filter"))
	mf:value("0", translate("Disable"))
	mf:value("2", translate("Allow listed only"))
	mf:value("1", translate("Allow all except listed"))

	ml = s:taboption("macfilter", DynamicList, "maclist", translate("MAC-List"))
	ml:depends({macfilter="2"})
	ml:depends({macfilter="1"})
	nt.mac_hints(function(mac, name) ml:value(mac, "%s (%s)" %{ mac, name }) end)

	bssid:depends({mode="wds"})
	bssid:depends({mode="adhoc"})
end


------------------- WiFI-Encryption -------------------

if hwtype == "broadcom" then
	wps = s:taboption("encryption", Flag, "wps_pbc", translate("Enable WPS Push Button"))
	wps:depends({encryption="none"})
	wps:depends({encryption="psk2"})
	wps:depends({encryption="pskmixedpsk2"})
end

encr = s:taboption("encryption", ListValue, "encryption", translate("Encryption"))
encr.override_values = true
encr.override_depends = true
encr:depends({mode="ap"})
encr:depends({mode="sta"})
encr:depends({mode="adhoc"})
encr:depends({mode="ahdemo"})
encr:depends({mode="ap-wds"})
encr:depends({mode="sta-wds"})
encr:depends({mode="mesh"})
encr:depends({mode="wds"})

cipher = s:taboption("encryption", ListValue, "cipher", translate("Cipher"))
cipher:depends({encryption="psk"})
cipher:depends({encryption="psk2"})
cipher:depends({encryption="pskmixedpsk2"})
cipher:value("auto", translate("auto"))
cipher:value("ccmp", translate("Force CCMP (AES)"))
cipher:value("tkip", translate("Force TKIP"))
cipher:value("tkip+ccmp", translate("Force TKIP and CCMP (AES)"))

function encr.cfgvalue(self, section)
	local v = tostring(ListValue.cfgvalue(self, section))
	if v == "wep" then
		return "wep-open"
	elseif v and v:match("%+") then
		return (v:gsub("%+.+$", ""))
	end
	return v
end

function encr.write(self, section, value)
	local e = tostring(encr:formvalue(section))
	local c = tostring(cipher:formvalue(section))
	if value == "wpa" or value == "wpa2"  then
		self.map.uci:delete("wireless", section, "key")
	end
	if e and (c == "tkip" or c == "ccmp" or c == "tkip+ccmp") then
		e = e .. "+" .. c
	end
	self.map:set(section, "encryption", e)
end

function cipher.cfgvalue(self, section)
	local v = tostring(ListValue.cfgvalue(encr, section))
	if v and v:match("%+") then
		v = v:gsub("^[^%+]+%+", "")
		if v == "aes" then v = "ccmp"
		elseif v == "tkip+aes" then v = "tkip+ccmp"
		elseif v == "aes+tkip" then v = "tkip+ccmp"
		elseif v == "ccmp+tkip" then v = "tkip+ccmp"
		end
	end
	return v
end

function cipher.write(self, section)
	return encr:write(section)
end


encr:value("none", "No Encryption")
encr:value("wep-open",   translate("WEP Open System"), {mode="ap"}, {mode="sta"}, {mode="ap-wds"}, {mode="sta-wds"}, {mode="adhoc"}, {mode="ahdemo"}, {mode="wds"})
encr:value("wep-shared", translate("WEP Shared Key"),  {mode="ap"}, {mode="sta"}, {mode="ap-wds"}, {mode="sta-wds"}, {mode="adhoc"}, {mode="ahdemo"}, {mode="wds"})

if hwtype == "broadcom" then
	encr:value("psk", "WPA-PSK", {mode="ap"}, {mode="wds"})
	encr:value("psk2", "WPA2-PSK", {mode="ap"}, {mode="wds"})
	encr:value("pskmixedpsk2", "WPA-PSK/WPA2-PSK Mixed Mode", {mode="ap"}, {mode="wds"})
	encr:value("wpa", "WPA-EAP", {mode="ap"})
	encr:value("wpa2", "WPA2-EAP", {mode="ap"})
	encr:value("wpamixedwpa2", "WPA-EAP/WPA2-EAP Mixed Mode", {mode="ap"})
end

radius_server = s:taboption("encryption", Value, "radius_server", translate("Radius-Authentication-Server"))
radius_server:depends({mode="ap", encryption="wpa"})
radius_server:depends({mode="ap", encryption="wpa2"})
radius_server:depends({mode="ap", encryption="wpamixedwpa2"})
radius_server:depends({mode="ap-wds", encryption="wpa"})
radius_server:depends({mode="ap-wds", encryption="wpa2"})
radius_server:depends({mode="ap-wds", encryption="wpamixedwpa2"})
radius_server.rmempty = true
radius_server.datatype = "host"

radius_port = s:taboption("encryption", Value, "radius_port", translate("Radius-Authentication-Port"))
radius_port:depends({mode="ap", encryption="wpa"})
radius_port:depends({mode="ap", encryption="wpa2"})
radius_port:depends({mode="ap", encryption="wpamixedwpa2"})
radius_port:depends({mode="ap-wds", encryption="wpa"})
radius_port:depends({mode="ap-wds", encryption="wpa2"})
radius_port:depends({mode="ap-wds", encryption="wpamixedwpa2"})
radius_port.rmempty = true
radius_port.datatype = "port"
radius_port.default = 1812

radius_secret = s:taboption("encryption", Value, "radius_secret", translate("Radius-Authentication-Secret"))
radius_secret:depends({mode="ap", encryption="wpa"})
radius_secret:depends({mode="ap", encryption="wpa2"})
radius_secret:depends({mode="ap", encryption="wpamixedwpa2"})
radius_secret:depends({mode="ap-wds", encryption="wpa"})
radius_secret:depends({mode="ap-wds", encryption="wpa2"})
radius_secret:depends({mode="ap-wds", encryption="wpamixedwpa2"})
radius_secret.rmempty = true
radius_secret.password = true

wpakey = s:taboption("encryption", Value, "_wpa_key", translate("Key"))
wpakey:depends("encryption", "psk")
wpakey:depends("encryption", "psk2")
wpakey:depends("encryption", "pskmixedpsk2")
wpakey:depends("encryption", "psk-mixed")
wpakey.datatype = "wpakey"
wpakey.rmempty = true
wpakey.password = true

gtk = s:taboption("encryption", Value, "gtk_rekey", translate("WPA Group Rekey Interval"))
gtk:depends({encryption="psk"})
gtk:depends({encryption="psk2"})
gtk:depends({encryption="pskmixedpsk2"})
gtk.default = 3600

wpakey.cfgvalue = function(self, section, value)
	local key = m.uci:get("wireless", section, "key")
	if key == "1" or key == "2" or key == "3" or key == "4" then
		return nil
	end
	return key
end

wpakey.write = function(self, section, value)
	self.map.uci:set("wireless", section, "key", value)
	self.map.uci:delete("wireless", section, "key1")
end


wepslot = s:taboption("encryption", ListValue, "_wep_key", translate("Used Key Slot"))
wepslot:depends("encryption", "wep-open")
wepslot:depends("encryption", "wep-shared")
wepslot:value("1", translatef("Key #%d", 1))
wepslot:value("2", translatef("Key #%d", 2))
wepslot:value("3", translatef("Key #%d", 3))
wepslot:value("4", translatef("Key #%d", 4))

wepslot.cfgvalue = function(self, section)
	local slot = tonumber(m.uci:get("wireless", section, "key"))
	if not slot or slot < 1 or slot > 4 then
		return 1
	end
	return slot
end

wepslot.write = function(self, section, value)
	self.map.uci:set("wireless", section, "key", value)
end

local slot
for slot=1,4 do
	wepkey = s:taboption("encryption", Value, "key" .. slot, translatef("Key #%d", slot))
	wepkey:depends("encryption", "wep-open")
	wepkey:depends("encryption", "wep-shared")
	wepkey.datatype = "wepkey"
	wepkey.rmempty = true
	wepkey.password = true

	function wepkey.write(self, section, value)
		if value and (#value == 5 or #value == 13) then
			value = "s:" .. value
		end
		return Value.write(self, section, value)
	end
end


return m
