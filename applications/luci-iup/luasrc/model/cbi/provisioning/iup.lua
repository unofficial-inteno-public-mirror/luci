
m = Map("provisioning", translate("IUP Provisioning"), translate("Setup your IUP Provisioning parameters"))



s = m:section(TypedSection, "general", "General")
s.anonymous=true


enapoll = s:option(Flag, "enabled", translate("Enabled"))
enapoll.enabled = "on"
enapoll.disabled = "off"
mintime = s:option(Value, "starttime", translate("Update interval start time (24 hour format ex 02)"))

function mintime:validate(value)
	return value:match("[0-9]+")
end

timelist = s:option(ListValue, "interval", translate("Update weekly or daily"))
timelist:value("weekly", translate("Weekly"))
timelist:value("daily", translate("Daily"))
timelist:value("hourly", translate("Hourly"))
backup=s:option(Button, "getprov", translate("Export file"),translate("Dump running config into a tar archive that can be used for IUP Provisioning"))




backup.write = function(self, section)
local backup_cmd  = "sysupgrade --create-backup-uci - 2>/dev/null"
local reader = ltn12_popen(backup_cmd)
		luci.http.header('Content-Disposition', 'attachment; filename="provisioning-%s-%s.tar.gz"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})
		luci.http.prepare_content("application/x-targz")
		luci.ltn12.pump.all(reader, luci.http.write)	
end
s2 = m:section(NamedSection,"configserver","server",translate ("Main Provisioning Server"), translate("If added will override DHCP Discover Provisioning"))
s2.anonymous=true

--s2.template = "cbi/tblsection"

enaser = s2:option(Flag, "enabled", translate("Enabled"))
enaser.enabled = "on"
enaser.disabled = "off"
enaser.rmempty = false

reboot = s2:option(Flag, "reboot", translate("Reboot"),translate("Reboot after settings config usualy needed for network settings to work properly"))
reboot.default="on"
reboot.enabled = "on"
reboot.disabled = "off"
reboot.rmempty = false

url = s2:option(Value, "url", translate("URL"))
--function url:validate(value)
--	return value:match("([fh][t][tp]?[ps]://[.]+)")
--end

deckey = s2:option(Value, "deckey", translate("Decryption Key"), translate("If not entered, Default onboard DES Key will be used instead"))
deckey.rmempty = true;
deckey.password = true;

s4 = m:section(NamedSection,"iup","server",translate ("DHCP Discover Provisioning Server"))

--s2.addremove = true
--s2.template = "cbi/tblsection"

enaiup = s4:option(Flag, "enabled", translate("Enabled"))
enaiup.enabled = "on"
enaiup.disabled = "off"
enaiup.rmempty = false


software = m:section(NamedSection,"uppgradeserver","software",translate ("Software Update Config"))
software.anonymous=true
 enab=software:option(Flag, "enabled", translate("Enabled"))
  enab.default = "off"
 enab.enabled = "on"
 enab.disabled = "off" 
 default=software:option(Flag, "defaultreset", translate("Defaultreset"),translate("Will remove any configuration set on the device and set it to software default"))
 default.enabled = "on"
 default.disabled = "off"
 software:option(Value, "url", translate("Software URL"))   


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
ena.rmempty = false
  
        


function ltn12_popen(command)

	local fdi, fdo = nixio.pipe()
	local pid = nixio.fork()

	if pid > 0 then
		fdo:close()
		local close
		return function()
			local buffer = fdi:read(2048)
			local wpid, stat = nixio.waitpid(pid, "nohang")
			if not close and wpid and stat == "exited" then
				close = true
			end

			if buffer and #buffer > 0 then
				return buffer
			elseif close then
				fdi:close()
				return nil
			end
		end
	elseif pid == 0 then
		nixio.dup(fdo, nixio.stdout)
		fdi:close()
		fdo:close()
		nixio.exec("/bin/sh", "-c", command)
	end
end

return m -- returns the map
