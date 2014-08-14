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

module("luci.controller.voice.moh", package.seeall)

function index()
	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do
		if user ~= "user"  then
			entry({user, "services", "voice", "moh"},	call("action_moh"),	"MOH",	26)
		end
	end
end

function action_moh()
	local sys = require "luci.sys"                                                                   
        local fs  = require "luci.fs"
	local nixio = require "nixio"

	local upload_tmp = "/tmp/sound.moh"
	local dest =  "/usr/lib/asterisk/moh"
	local filename

	local fp
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta and meta.name == "sound" then
					filename = meta.file
					fp = io.open(upload_tmp, "w")
				end
			end
			if chunk then
				fp:write(chunk)
			end
			if eof then
				fp:close()
			end
		end
	)

	function reload_moh()
		sys.exec("touch /etc/asterisk/musiconhold.conf")
		sys.exec("asterisk -rx 'moh reload'")
	end

	if luci.http.formvalue("upload") then
		local upload = luci.http.formvalue("sound")
		if upload and #upload > 0 then
			-- Create destination dir if it doesn't already exist
			stat = nixio.fs.stat(dest, "type")
			if not stat then
				nixio.fs.mkdir(dest)
			end
			-- Move upload
			nixio.fs.move(upload_tmp, dest .. "/" .. filename)
			-- Reload asterisk musiconhold module
			reload_moh()
		end
	end
	if luci.http.formvalue("remove") and luci.http.formvalue("file") then
		file = luci.http.formvalue("file")
		-- Check that user is not trying to delete a file outside of the moh directory
		if file == file:gsub("../", "") then
			nixio.fs.unlink(dest .. "/" .. file)
			reload_moh()
		end
	end	

	-- Read list of files
	local sound_files = {}
	stat = nixio.fs.stat(dest, "type")
	if stat then
		for e in nixio.fs.dir(dest) do
			table.insert(sound_files, e)
		end
	end
	
	luci.template.render("voice/moh", {
		sounds = {},
		sound_files = sound_files
	})
end
