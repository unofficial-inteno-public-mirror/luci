
m = Map("provisioning", translate("IUP Provisioning"), translate("Setup your IUP provisioning parameters"))



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
backup=s:option(Button, "getprov", translate("Exportfile"),translate("Dump running config into a tar archive that can be used for iup Provsioning"))




backup.write = function(self, section)
local backup_cmd  = "sysupgrade --create-backup-uci - 2>/dev/null"
local reader = ltn12_popen(backup_cmd)
		luci.http.header('Content-Disposition', 'attachment; filename="backup-%s-%s.tar.gz"' % {
			luci.sys.hostname(), os.date("%Y-%m-%d")})
		luci.http.prepare_content("application/x-targz")
		luci.ltn12.pump.all(reader, luci.http.write)	
end
s2 = m:section(NamedSection,"configserver","server",translate ("Main Provisioning Server"), translate("If added will override DHCP Discover Provisioning"))

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
s4 = m:section(NamedSection,"iup","server",translate ("DHCP Discover Provisioning Server"))

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
