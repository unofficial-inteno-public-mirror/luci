--[[
Configuration of physical lines (FXS and DECT)
]]--

local datatypes = require("luci.cbi.datatypes")
local vc = require "luci.model.cbi.voice.common"

default_extension = 0

m = Map ("voice_pbx", "FXS and DECT Settings")
s = m:section(TypedSection, "brcm_line")
s.template  = "cbi/tblsection"
s.anonymous = true

-- Only show configuration for lines that actually exist
function s.filter(self, section)
	line_number = tonumber(section:match("%d+"))
	return line_number < allCount
end

-- Show line title
title = s:option(DummyValue, "name", "Line")

-- Show line extension
exten = s:option(Value, "extension", "Extension")
exten.default = default_extension..default_extension..default_extension..default_extension
default_extension = default_extension + 1
function exten.validate(self, value, section)
	return vc.validate_extension(value, section)
end

-- Show SIP account selection
sip_provider = s:option(ListValue, "sip_provider", "Call out using SIP provider")
m.uci:foreach("voice_pbx", "sip_service_provider",
	function(s1)
		if s1.enabled == "1" then
			sip_provider:value(s1['.name'], s1.name)
		end
	end)
sip_provider:value("-", "-")
sip_provider.default = "-"

-- BRCM advanced common settings ----------------------------------------------
brcm = m:section(TypedSection, "brcm_advanced", "Advanced settings")
brcm.anonymous = true

countries = {	AUS = "AUSTRALIA",
		BEL = "BELGIUM",
		BRA = "BRAZIL",
		CHL = "CHILE",
		CHN = "CHINA",
		CZE = "CZECH",
		DNK = "DENMARK",
		ETS = "ETSI",
		FIN = "FINLAND",
		FRA = "FRANCE",
		DEU = "GERMANY",
		HUN = "HUNGARY",
		IND = "INDIA",
		ITA = "ITALY",
		JPN = "JAPAN",
		NLD = "NETHERLANDS",
		NZL = "NEW ZEALAND",
		USA = "NORTH AMERICA",
		ESP = "SPAIN",
		SWE = "SWEDEN",
		CHE = "SWITZERLAND",
		NOR = "NORWAY",
		TWN = "TAIWAN",
		GBR = "UK",
		ARE = "UNITED ARAB EMIRATES",
		T57 = "CFG TR57" }

country = brcm:option(ListValue, 'country', 'Locale selection', 'A restart is required for country changes to take effect')
for k,v in pairs(countries) do
	country:value(k, v)
end
country.default = "SWE"

jbenable = brcm:option(Flag, "jbenable", "Enable Jitter Buffer")
jbenable.disabled = "no"
jbenable.enabled = "yes"

jbforce = brcm:option(Flag, "jbforce", "Force Jitter Buffer")
jbforce:depends("jbenable", "yes")
jbforce.disabled = "no"
jbforce.enabled = "yes"

jbimpl = brcm:option(ListValue, "jbimpl", "Jitter Buffer implementation")
jbimpl:depends("jbenable", "yes")
jbimpl:value("fixed", "Fixed")
jbimpl:value("adaptive", "Adaptive")

jbmaxsize = brcm:option(Value, "jbmaxsize", "Maximum Jitter Buffer size, ms")
jbmaxsize.default = "500"
jbmaxsize:depends("jbenable", "yes")
function jbmaxsize.validate(self, value, section)
	if datatypes.uinteger(value) then
		return value
	end
	return nil, "Maximum Jitter Buffer size must be a positive number of milliseconds"
end

plc = brcm:option(Flag, "genericplc", "Enable Packet Loss Concealment")
plc:depends("jbenable", "yes")
plc.disabled = "no"
plc.enabled = "yes"

dialoutmsec = brcm:option(Value, "dialoutmsec", "Inter-digit timeout")
function dialoutmsec.validate(self, value, section)
	if datatypes.uinteger(value) then
		return value
	end
	return nil, "Inter-digit timeout must be a positive number of milliseconds"
end

-- BRCM advanced line settings ----------------------------------------------
line = m:section(TypedSection, "brcm_line")
line.template  = "cbi/tblsection"
line.anonymous = true

-- Only show configuration for lines that actually exist
function line.filter(self, section)
	line_number = tonumber(section:match("%d+"))
	return line_number < allCount
end

-- Show line title
title = line:option(DummyValue, "name", "Line")

ptime = line:option(ListValue, "ptime", "Preferred ptime")
ptime:value("5", "5")
ptime:value("10", "10")
ptime:value("20", "20")
ptime:value("30", "30")
ptime:value("40", "40")
ptime.default = "20"

ecan = line:option(Flag, "echo_cancel", "Echo cancellation")
ecan.rmempty = false

vad = line:option(ListValue, "vad", "Voice Activity Detection")
vad:value(0, "Off")
vad:value(1, "Transparent")
vad:value(2, "Conservative")
vad:value(3, "Aggressive")
vad.default = 0

noise = line:option(ListValue, "noise", "Comfort Noise Generation")
noise:value(0, "Off")
noise:value(1, "White noise")
noise:value(2, "Hot noise")
noise:value(3, "Spectrum estimate")
noise.default = 0

txgain = line:option(Value, "txgain", "Tx Gain", "Between -96 and 32 dB")
txgain.default = 0
function txgain.validate(self, value, section)
	if datatypes.range(value,-96,32) then
		return value
	end
	return nil, "Tx Gain must be between -96 and 32 dB"
end

rxgain = line:option(Value, "rxgain", "Rx Gain", "Between -96 and 32 dB")
rxgain.default = 0
function rxgain.validate(self, value, section)
	if datatypes.range(value,-96,32) then
		return value
	end
	return nil, "Rx Gain must be between -96 and 32 dB"
end

-- jmin = line:option(Value, 'jitter_min', 'Jitter min')
-- jmin.datatype = "integer"
-- jmax = line:option(Value, 'jitter_max', 'Jitter max')
-- jmax.datatype = "integer"
-- jtarg = line:option(Value, 'jitter_target', 'Jitter target')
-- jtarg.datatype = "integer"


return m
