local dsp = require "luci.dispatcher"

m = Map ("voice_client", translate("Voice Settings"))
function m.on_before_apply(self)
	redirect = dsp.build_url("admin/system/reboot")
	luci.http.redirect(redirect)
end

brcm = m:section(TypedSection, "brcm_advanced")
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

voice_ver = brcm:option(DummyValue, "voiceversion", "")
function voice_ver.cfgvalue(self, section)
        v = luci.sys.exec("opkg find luci-app-voice-client")
        if not v or #v < 1 then
                v = "Unknown luci-app-voice-client version"
        end
        return v
end

ast_ver = brcm:option(DummyValue, "astversion", "")
function ast_ver.cfgvalue(self, section)
        v = luci.sys.exec("opkg find asterisk18-mod")
        if not v or #v < 1 then
                v = "Unknown asterisk18-mod version"
        end
        return v
end

return m
