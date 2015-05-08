local ringing_schedule_common = {}

require("uci")
local datatypes = require "luci.cbi.datatypes"

function ringing_schedule_common.validate_time(time)

	local pattern = "(%d%d):(%d%d) (%d%d):(%d%d)"
	from_hour, from_minute, to_hour, to_minute = time:match(pattern)
	if from_hour == nil or from_minute == nil or to_hour == nil or to_minute == nil then
		return nil, "Invalid time, expected 'HH::MM HH:MM'"
	end
	
	if tonumber(from_hour) > 23 or
		tonumber(from_minute) > 59 or
		tonumber(to_hour) > 23 or
		tonumber(to_minute) > 59
	then
		return nil, "Invalid time, expected 'HH::MM HH:MM'"
	end

	if from_hour > to_hour or from_hour <= to_hour and from_minute > to_minute then
		return nil, "Start time is after end time"
	end
	
	return time
end

return ringing_schedule_common
