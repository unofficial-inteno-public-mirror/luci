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
]]--

local datatypes = require("luci.cbi.datatypes")

m = Map ("voice_pbx", translate("Advanced settings"))

-- SIP common settings --------------------------------------------------------
sip = m:section(TypedSection, "sip_advanced", "Advanced SIP settings")
sip.anonymous = true

proxy = sip:option(DynamicList, "sip_proxy", "SIP Proxy servers", "Allow incoming calls from the specified proxies")
proxy.optional = true
function proxy.validate(self, value, section)
	for k,v in pairs(value) do
		if not datatypes.host(v) then
			return nil, "SIP Proxy must be a hostname or ip address: " .. v
		end
	end
	return value
end

bindport = sip:option(Value, 'bindport', "Bindport", "UDP Port to bind to (listen on)")
bindport.optional = true
bindport.default = 5060
function bindport.validate(self, value, section)
	if datatypes.port(value) then
		return value
	end
	return nil, "Bindport is invalid"
end

useragent = sip:option(Value, 'useragent', "User Agent", "Allow the SIP header User-Agent to be customized")
useragent.optional = true
useragent.default = "VOICE"

rtpstart = sip:option(Value, 'rtpstart', "RTP Port Range start")
rtpstart.default = 10000
function rtpstart.validate(self, value, section)
	local rtpend = self.map:formvalue("cbid."..self.map.config.."."..section..".rtpend")

	if datatypes.port(value) then
		if rtpend and datatypes.port(rtpend) and tonumber(rtpend) < tonumber(value) then
			return nil, "RTP Port Range start value is higher than end value"
		end
		return value
	end
	return nil, "RTP Port Range start is invalid"
end

rtpend = sip:option(Value, 'rtpend', "RTP Port Range end")
rtpend.default = 20000
function rtpend.validate(self, value, section)
	if datatypes.port(value) then
		return value
	end
	return nil, "RTP Port Range end is invalid"
end

dtmfmode = sip:option(ListValue, "dtmfmode", "DTMF Mode")
dtmfmode:value("compatibility", "Compatibility")
dtmfmode:value("rfc2833", "RFC 2833")
dtmfmode:value("info", "SIP INFO")
dtmfmode:value("inband", "Inband")
dtmfmode.default = "compatibility"

defaultexpiry = sip:option(Value, 'defaultexpiry', "Register Interval", "Time in seconds between registration attempts");
defaultexpiry.default = 300
function defaultexpiry.validate(self, value, section)
	if datatypes.min(value,1) then
		return value
	end
	return nil, "Register Interval must be at least 1 second"
end

realm = sip:option(Value, 'realm', "Realm", "Realm for digest authentication, set this to your host name or domain name");
localnet = sip:option(DynamicList, 'localnet', "Localnet", "Network addresses that are considered inside of the NATted network");

advanced_register_settings = m.uci.get("voice_pbx", "features", "advanced_register_settings") == "1"
if advanced_register_settings then
	registertimeout = sip:option(Value, 'registertimeout', "Register Timeout", "Time before giving up a registration attempt");
	registertimeout.default = 30
	registertimeout.optional = true
	function registertimeout.validate(self, value, section)
		if datatypes.min(value,1) then
			return value
		end
		return nil, "Register Timeout must be at least 1 second"
	end

	registerattempts = sip:option(Value, 'registerattempts', "Register Attempts", "Number of registration attempts before giving up (Set to 0 or empty to try forever)");
	registerattempts.default = 0
	registerattempts.optional = true
	function registerattempts.validate(self, value, section)
		if datatypes.min(value,0) then
			return value
		end
		return nil, "Register Attempts must be at least 1"
	end
end

remotehold = sip:option(Flag, 'remotehold', "Remote Hold", "Send hold events to proxy (Let network handle music on hold)")
remotehold.optional = true
remotehold.disabled = "no"                              
remotehold.enabled = "yes"

contact_line_suffix = sip:option(Flag, 'contact_line_suffix', "Line suffix in contact header", "Add a suffix indicating which lines are called to the sip contact header")
contact_line_suffix.optional = true

blindxfer = sip:option(Value, 'blindxfer', "Blind Transfer", "Key combination to initiate blind transfer of call")
function blindxfer.validate(self, value, section)
	if datatypes.phonedigit(value) then
		return value
	end
	return nil, "Not a valid key for Blind Transfer"
end

tos_sip = sip:option(Value, 'tos_sip', "SIP DiffServ", "Differentiated services/TOS for SIP data. Recommended value: cs3")
tos_sip.default = "cs3"
tos_sip.optional = true

tos_audio = sip:option(Value, 'tos_audio', "Audio DiffServ", "Differentiated services/TOS for Audio data. Recommended value: ef")
tos_audio.default = "ef"
tos_audio.optional = true

--tos_video = sip:option(Value, 'tos_video', "Video DiffServ", "Differentiated services/TOS for Video data. Recommended value: af41")
--tos_video.default = "af41"
--tos_video.optional = true

--tos_text = sip:option(Value, 'tos_text', "Text DiffServ", "Differentiated services/TOS for Text data. Recommended value: af41")
--tos_text.default = "af41"
--tos_text.optional = true

congestiontone = sip:option(ListValue, "congestiontone", "Congestion tone", "Tone to play on congestion")
congestiontone:value("congestion", "congestion")
congestiontone:value("info", "info")
congestiontone.optional = true

-- Fixed length numbers
s = m:section(TypedSection, "sip_service_provider", "Fixed length number series")
s.template  = "cbi/tblsection"
s.anonymous = true
s:option(DummyValue, 'name', "SIP Account")
s:option(DynamicList, "direct_dial", "Define number series with a prefix and a total length. Example: 0520XXXXXX (a 10 digit number starting with 0520)")

-- Call Return and Redial
callreturn_enabled = m.uci.get("voice_pbx", "features", "callreturn_enabled") == "1"
redial_enabled = m.uci.get("voice_pbx", "features", "redial_enabled") == "1"

if callreturn_enabled and redial_enabled then
	s = m:section(TypedSection, "sip_service_provider", "Call Return and Redial", "Key combinations for Call Return and Redial activation")
elseif callreturn_enabled then
	s = m:section(TypedSection, "sip_service_provider", "Call Return", "Key combination for Call Return activation")
elseif redial_enabled then
	s = m:section(TypedSection, "sip_service_provider", "Redial", "Key combination for Redial activation")
end

if callreturn_enabled or redial_enabled then
	s.template  = "cbi/tblsection"
	s.anonymous = true
	s:option(DummyValue, 'name', "SIP Account")
end

if callreturn_enabled then
	callreturn = s:option(Value, 'call_return', "Call Return", "Dial last caller, even if call was not answered")
	function callreturn.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key combination for Call Return"
	end
end

if redial_enabled then
	redial = s:option(Value, 'redial', "Redial", "Redial last called number")
	function redial.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key combination for Redial"
	end
end

-- Call Forwarding settings
if m.uci.get("voice_pbx", "features", "callforward_enabled") == "1" then
	s = m:section(TypedSection, "sip_service_provider", "Call Forwarding", "Key combinations for Call Forwarding activation/deactivation")
	s.template  = "cbi/tblsection"
	s.anonymous = true

	s:option(DummyValue, 'name', "SIP Account")
	cfim_on = s:option(Value, 'cfim_on', "Call Forwarding Unconditional activation")
	function cfim_on.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key combination for Call Forwarding Unconditional activation"
	end

	cfim_off = s:option(Value, 'cfim_off', "Call Forwarding Unconditional deactivation")
	function cfim_off.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key combination for Call Forwarding Unconditional deactivation"
	end

	cfbs_on = s:option(Value, 'cfbs_on', "Call Forwarding Busy/No reply activation")
	function cfbs_on.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key combination for Call Forwarding Busy/No reply activation"
	end

	cfbs_off = s:option(Value, 'cfbs_off', "Call Forwarding Busy/No reply deactivation")
	function cfbs_off.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key combination for Call Forwarding Busy/No reply deactivation"
	end
end

-- Call Back Busy Subscriber
if m.uci.get("voice_pbx", "features", "cbbs_enabled") == "1" then
	s = m:section(TypedSection, "sip_service_provider", "Call Back Busy Subscriber")
	s.template  = "cbi/tblsection"
	s.anonymous = true

	s:option(DummyValue, 'name', "SIP Account")

	cbbs_key = s:option(Value, 'cbbs_key', "CBBS key", "Call Back Busy Subscriber key")
	function cbbs_key.validate(self, value, section)
		if datatypes.phonedigit(value) then
			return value
		end
		return nil, "Not a valid key for CBBS"
	end

	cbbs_maxretry = s:option(Value, 'cbbs_maxretry', "CBBS retries", "Max number of redial attempts to make (0 - 20)")
	cbbs_maxretry.default = "5"
	function cbbs_maxretry.validate(self, value, section)
		if datatypes.range(value,0,20) then
			return value
		end
		return nil, "CBBS retries must be in range 0-20"
	end

	cbbs_retrytime = s:option(Value, 'cbbs_retrytime', "CBBS retry interval", "Seconds between redial attempts (30 to 600)")
	cbbs_retrytime.default = "300"
	function cbbs_retrytime.validate(self, value, section)
		if datatypes.range(value,30,600) then
			return value
		end
		return nil, "CBBS retry interval must be in range 30-600 seconds"
	end

	cbbs_waittime = s:option(Value, 'cbbs_waittime', "CBBS wait time", "Seconds to wait for answer (15 - 300)")
	cbbs_waittime.default = "30"
	function cbbs_waittime.validate(self, value, section)
		if datatypes.range(value,15,300) then
			return value
		end
		return nil, "CBBS wait time must be in range 15-300 seconds"
	end
end

s = m:section(TypedSection, "language", "Language", "Upload sound files to be used for various voice services")
s.anonymous = true
s.addremove = false
upload = s:option(FileUpload, 'voice_pack', 'Voice-pack', "The voice-pack must contain a single directory named <strong>sounds</strong> and compressed as <strong>tar.gz</strong>")

return m
