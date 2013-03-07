local fs = require "nixio.fs"
local sys = require "luci.sys"

module "luci.ihgsp"


function get_version()
	return sys.exec("cat /etc/banner | grep Version | sed 's/IOP Version://'")  
end


function get_brcmversion()
	return sys.exec("cat /etc/banner | grep BrcmRef | sed 's/BrcmRef Base://'")  
end

name    = "IHGSP"
version = get_version()
brcmversion = get_brcmversion()

