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
	m = luci.cbi.Map("voice_client", nil)
	for _,t in pairs(types) do
		if t == 'brcm' then
			lineCount = 0
			m.uci:foreach("voice_client", "brcm_line",
				function(s1)
					if lineCount < allCount then
						-- Make sure name is set
						if not s1["name"] then
							s1["name"] = common.line2name(lineCount)
						end
						func(s1)
					end
					lineCount = lineCount + 1
				end
			)
		end
		if t == 'sip' then
			m.uci:foreach("voice_client", "sip_user",
				function(s1)
					func(s1)
				end
			)
		end
		if t == 'queue' then
			m.uci:foreach("voice_client", "queue",
				function(s1)
					func(s1)
				end
			)
		end
		if t == 'ivr' then
			m.uci:foreach("voice_client", "ivr",
				function(s1)
					func(s1)
				end
			)
		end
	end
end

function common.line2name(lineno)
	if lineno < 4 then
		return "DECT" .. (lineCount + 1)
	else
		return "Tel" .. (lineCount - 3)
	end
end

function common.user2name(user)
	local name
	common.foreach_user({'brcm', 'sip', 'queue', 'ivr'},
		function(v)
			if v['.name'] == user then
				name = v['name']
				return false
			end
		end
	)
	m.uci:foreach("voice_client", "sip_service_provider",
		function(v)
			if v['.name'] == user then
				name = v['name']
				return false
			end
		end
	)
	if name then
		return name
	else
		return ""
	end
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

function common.has_package(name)
	out = luci.sys.exec("opkg find " .. name)
	lines = string.split(out, "\n")
	for i, line in ipairs(lines) do
		if line and line:sub(0, #name) == name then
			return true
		end
	end
	return false
end

function common.add_section(name)
	x = uci.cursor()
	s = x:get("voice_client", name)
	if not s then
		x:set("voice_client", name, name)
		x:commit("voice_client")
	end
end

return common

