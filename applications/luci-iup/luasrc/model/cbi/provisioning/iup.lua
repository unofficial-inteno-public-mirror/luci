
m = Map("provisioning", translate("IUP Provisioning"), translate("Setup Your IUP provisioning parameters")) 

s = m:section(TypedSection, "general", "General") -- Configure atm interface
enapoll = s:option(Flag, "enabled", translate("Enabled"))
enapoll.enabled = "on"
enapoll.disabled = "off"
mintime = s:option(Value, "starttime", translate("Update interval Start time (24 hour format ex 02)"))

function mintime:validate(value)
	return value:match("[0-9]+")
end

timelist = s:option(ListValue, "interval", translate("update weekly or daily"))
timelist:value("weekly", translate("Weekly"))
timelist:value("daily", translate("Daily"))

s2 = m:section(NamedSection,"configserver","server",translate ("Main Provisioning Server"), translate("If Added will override Dhcp Discover Provisioning"))

s2.addremove = true
--s2.template = "cbi/tblsection"

enaser = s2:option(Flag, "enabled", translate("Enabled"))
enaser.enabled = "on"
enaser.disabled = "off"
enaser.rmempt = false

url = s2:option(Value, "url", translate("URL"))
--function url:validate(value)
--	return value:match("([fh][t][tp]?[ps]://[.]+)")
--end
s4 = m:section(NamedSection,"iup","server",translate ("Dhcp Discover Provisioning Server"))

--s2.addremove = true
--s2.template = "cbi/tblsection"

enaiup = s4:option(Flag, "enabled", translate("Enabled"))
enaiup.enabled = "on"
enaiup.disabled = "off"
enaiup.rmempt = false




s3 = m:section(TypedSection, "subconfig", translate("Sub Configs"))
s3.anonymous = true
s3.addremove = true
s3.template = "cbi/tblsection"

url= s3:option(Value, "url", translate("URL"))
--function url:validate(value)
--	return value:match("([fh][t][tp]?[ps]://[.]+)")
--end
s3:option(Value, "packagecontrol", translate("Package Control"))
ena = s3:option(Flag, "enabled", translate("Enabled"))
ena.enabled = "on"
ena.disabled = "off"
ena.rmempt = false
return m -- returns the map




