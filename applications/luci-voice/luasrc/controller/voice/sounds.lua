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

module("luci.controller.voice.sounds", package.seeall)

function index()
	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do
		if user ~= "user"  then
			entry({user, "services", "voice", "sounds"},	call("action_sounds"),	"Sounds",	26)
		end
	end
end

function action_sounds()
	local sys = require "luci.sys"                                                                   
        local fs  = require "luci.fs"
	local nixio = require "nixio"
	local vc = require "luci.model.cbi.voice.common"
	require "luci.util"
	require "uci"

	local upload_tmp = "/tmp/sounds.tmp"
	local recordingsdir = "/usr/lib/asterisk/recordings"
	local extradir = "/usr/lib/asterisk/extra"
	local soundsdir = "/usr/lib/asterisk/sounds"
	local filename
	local msg = ""

	local fp
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not fp then
				if meta then
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

	function handle_sound_pack()
		-- Create a working directory
		workdir = luci.sys.exec("mktemp -d"):match("^%s*(.-)%s*$")
		res = unpack_archive(upload_tmp, workdir)
		luci.sys.call("rm -rf " .. workdir)
		return res
	end

	function unpack_archive(archive, workdir)
		nixio.fs.move(archive, workdir .. "/archive.tar.gz")
		if sys.call("gunzip -t " .. workdir .. "/archive.tar.gz 2>/dev/null") ~= 0 then
			msg = "Not a gzip archive"
			return false
		end
	
		-- Decompress
		if sys.call("gunzip -f " .. workdir .. "/archive.tar.gz 2>/dev/null") ~= 0 then
			msg = "Could not decompress archive"
			return false
		end

		luci.sys.call("mkdir " .. workdir .. "/sounds")
		-- Extract archive
		if luci.sys.call("tar -C " .. workdir .. "/sounds" .. " -xf " .. workdir .. "/archive.tar 2>/dev/null") ~= 0 then
			msg = "Unpack of archive failed"
			return false
		else
			luci.sys.call("rm -rf /usr/lib/asterisk/sounds")
			luci.sys.call("mv " .. workdir .. "/sounds /usr/lib/asterisk")
		end
		return true
	end

	if luci.http.formvalue("upload") then
		local upload = luci.http.formvalue("extra_sound")
		if upload and #upload > 0 then
			-- Create destination dir if it doesn't already exist
			stat = nixio.fs.stat(extradir, "type")
			if not stat then
				nixio.fs.mkdir(extradir)
			end
			-- Move upload
			nixio.fs.move(upload_tmp, extradir .. "/" .. filename)
		end

		local upload = luci.http.formvalue("sound_pack")
		if upload and #upload > 0 then
			if handle_sound_pack() then
				msg = "System sound files successfully replaced"
			end
		end
	end
	if luci.http.formvalue("remove_recording") and luci.http.formvalue("file") then
		file = luci.http.formvalue("file")
		-- Check that user is not trying to delete a file outside of the directory
		if file == file:gsub("../", "") then
			nixio.fs.unlink(recordingsdir .. "/" .. file)
		end
	end
	if luci.http.formvalue("remove_extra") and luci.http.formvalue("file") then
		file = luci.http.formvalue("file")
		-- Check that user is not trying to delete a file outside of the directory
		if file == file:gsub("../", "") then
			nixio.fs.unlink(extradir .. "/" .. file)
		end
	end	

	-- Read list of ivr sounds
	local extra_sounds = {}
	stat = nixio.fs.stat(extradir, "type")
	if stat then
		for e in nixio.fs.dir(extradir) do
			table.insert(extra_sounds, { file = e })
		end
	end

	x = uci.cursor()	
	rme = x:get("voice_client", "custom_dialplan", "record_message_extension")
	if not rme or #rme == 0 then
		rme = "N/A"
	end

	luci.template.render("voice/sounds", {
		recordings = vc.get_recordings(),
		record_message_extension = rme,
		extra_sounds = extra_sounds,
		msg = msg
	})
end
