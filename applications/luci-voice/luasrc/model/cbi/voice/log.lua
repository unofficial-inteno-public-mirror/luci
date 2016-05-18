--[[
	Displays a log of phone calls, optionally allowing a user to initiate a call
	by the press of a button (click-to-dial)
]]--

local vc = require "luci.model.cbi.voice.common"

-- This function was copied from http://lua-users.org/wiki/LuaCsv 2015-05-22
function ParseCSVLine (line,sep)
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos)
				if (c == '"') then txt = txt..'"' end
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--	value1,"blub""blip""boing",value3	will result in blub"blip"boing	for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end
		end
	end
	return res
end

-- Function that reads call log into a table
function get_call_log()
	local calls = {}
	file = nixio.fs.readfile("/var/log/asterisk/cdr-csv/Master.csv")
	if not file then
		return calls
	end
	lines = string.split(file, "\n")
	for i,line in ipairs(lines) do
		values = ParseCSVLine(line, ",")
		if (table.getn(values) >= 4) then
			local direction
			-- If context name starts with sip it must be an outgoing call
			if string.sub(values[4], 0, 3) == "sip" then
				direction = "Outgoing"
			else
				direction = "Incoming"
			end
			d = tonumber(values[14])
			duration = string.format("%02.0f:%02.0f:%02.0f", d / (60 * 60), (d / 60) % 60, d % 60)
			to = values[3]
			-- Strip any suffixes
			k1, k2 = string.find(to, "_")
			if k1 ~= nil then
				to = string.sub(to, 1, k1 - 1)
			end
			calls[i] = {
				time = values[10],
				direction = direction,
				from = values[2],
				to = to,
				duration = duration,
				uniqueid = values[17],
				disposition = values[15]
			}
		end
	end
	return calls
end

-- Create a asterisk call file in temporary directory, then reload page
function create_call_file(self, section)
	to = self.map:get(section, "to")
	value = "Channel: BRCM/" .. self.line .. "\n"
	value = value .. "CallerID: \"\"<" .. to .. ">\n"
	value = value .. "Context: " .. self.context .. "\n"
	value = value .. "Extension: " .. to .. "\n"
	value = value .. "Priority: 1\n"
	nixio.fs.writefile("/tmp/clicktodial.tmp", value)
	luci.http.redirect(luci.dispatcher.build_url("admin/services/voice/log", to))
end

function remove_cdr(self, section)
	unique_id = self.map:get(section, "uniqueid")
	if unique_id then
		os.execute('asterisk -rx "cdr_csv remove cdr ' .. unique_id .. '"')
	end
	luci.http.redirect(luci.dispatcher.build_url("admin/services/voice/log"))
end

-- Return user to the call log
function back_to_log(self, section)
	luci.http.redirect(luci.dispatcher.build_url("admin/services/voice/log"))
end

voice_map = Map("voice_client")
function render_call_button(section, line_nr, title)
	sip_provider = voice_map.uci:get("voice_client", "brcm"..line_nr, "sip_account")
	if not sip_provider then
		return
	end

	btn = section:option(Button, "btn"..line_nr, title)
	btn.write = create_call_file
	btn.context = sip_provider.."-outgoing"
	btn.line = line_nr
end

-- If there is a call file waiting, place it in asterisk spool directory
if nixio.fs.stat("/tmp/clicktodial.tmp") then
	nixio.fs.move("/tmp/clicktodial.tmp", "/var/spool/asterisk/outgoing/clicktodial.call")
	if arg[1] then
		title = "Calling " .. arg[1]
	else
		title = "Calling"
	end

	m = SimpleForm("_log", title)
	m.reset = false
	m.submit = false
	s = m:section(SimpleSection)
	b = s:option(Button, "back", "Back to Log")
	b.write = back_to_log
	return m
-- Show call log table
else
	m = SimpleForm("_log", "Call Log", "Incoming and outgoing calls")
	m.reset = false
	m.submit = false

	-- Create a Table section
	s = m:section(Table, get_call_log(), "")
	s.template = "voice/rtblsection"
	s:option(DummyValue, "time", "Time")
	s:option(DummyValue, "direction", "Direction")
	s:option(DummyValue, "from", "From")
	s:option(DummyValue, "to", "To")
	s:option(DummyValue, "disposition", "Disposition")
	s:option(DummyValue, "duration", "Duration")

	-- Add delete button
	btn = s:option(Button, "uniqueid", "Remove")
	btn.write = remove_cdr

	-- Add a Call button for each local line
	line_nr = 0
	-- DECT
	for i = 1, dectCount do
		render_call_button(s, line_nr, "Call from DECT " .. i)
		line_nr = line_nr + 1
	end

	-- FXS
	for i = 1, fxsCount do
		render_call_button(s, line_nr, "Call from Tel " .. i)
		line_nr = line_nr + 1
	end

	return m
end
