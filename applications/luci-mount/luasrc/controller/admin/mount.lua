module("luci.controller.admin.mount", package.seeall)

function index()
	if nixio.fs.access("/etc/config/fstab") then
		entry({"admin", "system", "fstab"}, cbi("admin_system/fstab"), _("Mount Points"), 50)
		entry({"admin", "system", "fstab", "mount"}, cbi("admin_system/fstab/mount"), nil).leaf = true
		entry({"admin", "system", "fstab", "swap"},  cbi("admin_system/fstab/swap"),  nil).leaf = true
	 end
end

