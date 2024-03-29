local common = {}

require("uci")
local datatypes = require "luci.cbi.datatypes"

-- Read line counts from driver
lineInfo = luci.sys.exec("/usr/bin/brcminfo")
lines = string.split(lineInfo, "\n")
line_nr = 0
if #lines == 5 then
	dectInfo = lines[1]
	dectCount = tonumber(dectInfo:match("%d+"))
	fxsInfo = lines[2]
	fxsCount = tonumber(fxsInfo:match("%d+"))
	allInfo = lines[4]
	allCount = tonumber(allInfo:match("%d"))
else
	dectCount = 0
	fxsCount = 0
	allCount = 0
end

function common.validate_extension(extension, user)
	if not datatypes.phonedigit(extension) then
		return nil, extension .. " is not a valid extension"
	end

	-- Check if already in use
	retval = extension
	errmsg = nil

	common.foreach_user({'brcm', 'sip', 'queue', 'ivr'},
		function(v)
			if user and v['.name'] == user then
				return
			end

			if v['extension'] == extension then
				retval = nil
				errmsg = "Extension " .. extension .. " is already in use"
			end
		end
	)
	return retval, errmsg
end

function common.foreach_user(types, func)
	m = luci.cbi.Map("voice_pbx", nil)
	for _,t in pairs(types) do
		if t == 'brcm' then
			lineCount = 0
			m.uci:foreach("voice_pbx", "brcm_line",
				function(s1)
					if lineCount < allCount then
						func(s1)
					end
					lineCount = lineCount + 1
				end
			)
		end
		if t == 'sip' then
			m.uci:foreach("voice_pbx", "sip_user",
				function(s1)
					func(s1)
				end
			)
		end
		if t == 'queue' then
			m.uci:foreach("voice_pbx", "queue",
				function(s1)
					func(s1)
				end
			)
		end
		if t == 'ivr' then
			m.uci:foreach("voice_pbx", "ivr",
				function(s1)
					func(s1)
				end
			)
		end
	end
end

function common.user2name(user)
	name = ""
	common.foreach_user({'brcm', 'sip', 'queue', 'ivr'},
		function(v)
			if v['.name'] == user then
				name = v['name']
				return false
			end
		end
	)
	m.uci:foreach("voice_pbx", "sip_service_provider",
		function(v)
			if v['.name'] == user then
				name = v['name']
				return false
			end
		end
	)
	return name
end

function common.get_recordings()
	local recordings = {}
	path = "/usr/lib/asterisk/recordings"
	i = 0
	if nixio.fs.stat(path) then
		for e in nixio.fs.dir(path) do
			recordings[i] = {
				file = e,
				name = string.sub(e, 0, 31),
				timestamp = string.sub(e, 15, 31),
				format = string.sub(e, 33)
			}
			i = i + 1
		end
	end
	return recordings
end

function common.get_custom_sounds()
	local files = {}
	path = "/usr/lib/asterisk/custom"
	i = 0
	if nixio.fs.stat(path) then
		for e in nixio.fs.dir(path) do
			-- get file name and file extension
			lastdotpos = -1
			for i = 1, #e do
				if e:sub(i, i) == "." then
					lastdotpos = i
				end
			end
			name = ""
			format = ""
			if lastdotpos ~= -1 then
				name = e:sub(0, lastdotpos - 1)
				format = e:sub(lastdotpos + 1)
			end
			files[i] = {
				file = e,
				name = name,
				format = format
			}
			i = i + 1
		end
	end
	return files
end

return common

