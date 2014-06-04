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
	i = 0
	for e in nixio.fs.dir("/usr/lib/asterisk/recordings") do
		recordings[i] = {
			file = e,
			name = string.sub(e, 0, 31),
			timestamp = string.sub(e, 15, 31),
			format = string.sub(e, 33)
		}
		i = i + 1
	end
	return recordings
end

return common

