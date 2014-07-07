local dsp = require "luci.dispatcher"

m = Map ("voice", translate("BRCM Country Settings"))
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

return m
