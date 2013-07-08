--[[
    Copyright 2011 Iordan Iordanov <iiordanov (AT) gmail.com>

    This file is part of luci-pbx.

    luci-pbx is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    luci-pbx is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with luci-pbx.  If not, see <http://www.gnu.org/licenses/>.

    Modified to luci-app-voice-client
]]--

module("luci.controller.voice", package.seeall)

function index()
	entry({"admin", "services", "voice"},			cbi("voice"),		"Voice",		80)
	entry({"admin", "services", "voice", "voice"},		cbi("voice"),		"Voice",		1)
	entry({"admin", "services", "voice", "voice_sip"},
		arcombine(cbi("voice_sip"), cbi("voice_sip_details")),
		_("SIP Providers"), 2).leaf = true
	entry({"admin", "services", "voice", "voice_brcm"},	cbi("voice_brcm"),	"Lines",		3)
	entry({"admin", "services", "voice", "voice_advanced"},	cbi("voice_advanced"),	"Advanced Settings",	4)
	entry({"admin", "services", "voice", "voice_dialplan"},	cbi("voice_dialplan"),	"Dialplan",		5)
	entry({"admin", "services", "voice", "voice_log"},	cbi("voice_log"),	"Call Log",		6).leaf = true
	entry({"admin", "status", "voice"},			cbi("voice_status"),	"SIP Registration",	80)

	entry({"support", "services", "voice"},			cbi("voice"),		"Voice",		80)
	entry({"support", "services", "voice", "voice"},	cbi("voice"),		"Voice",		1)
	entry({"support", "services", "voice", "voice_sip"},
		arcombine(cbi("voice_sip"), cbi("voice_sip_details")),
		_("SIP Providers"), 2).leaf = true
	entry({"support", "services", "voice", "voice_brcm"},	cbi("voice_brcm"),	"Lines",		3)
	entry({"support", "services", "voice", "voice_log"},	cbi("voice_log"),	"Call Log",		6).leaf = true
	entry({"support", "status", "voice"},			cbi("voice_status"),	"SIP Registration",	80)

	entry({"user", "services", "voice"},			cbi("voice"),		"Voice",		80)
	entry({"user", "services", "voice", "voice"},		cbi("voice"),		"Voice",		1)
	entry({"user", "services", "voice", "voice_sip"},
		arcombine(cbi("voice_sip"), cbi("voice_sip_details")),
		_("SIP Providers"), 2).leaf = true
	entry({"user", "services", "voice", "voice_brcm"},	cbi("voice_brcm"),	"Lines",		3)
	entry({"user", "services", "voice", "voice_log"},	cbi("voice_log"),	"Call Log",		6).leaf = true
	entry({"user", "status", "voice"},			cbi("voice_status"),	"SIP Registration",	80)
end
