--[[
	Displays a log of phone calls, optionally allowing a user to initiate a call
	by the press of a button (click-to-dial)
]]--

local vc = require "luci.model.cbi.voice.common"

-- Function that reads call log into a table
function get_call_log()
	local calls = {}
	file = nixio.fs.readfile("/var/call_log")
	if not file then
		return calls
	end
	lines = string.split(file, "\n")
	for i,line in ipairs(lines) do
		values = string.split(line, ";")
		if (table.getn(values) >= 4) then
			calls[i] = {
				time = values[1],
				direction = values[2],
				from = values[3],
				to = values[4],
				note = ""
			}
			if (table.getn(values) >= 5) then
				calls[i].note = values[5]
			end
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
	m = SimpleForm("_log", "Call Log", "Last 100 incoming/outgoing calls")
	m.reset = false
	m.submit = false

	-- Create a Table section
	s = m:section(Table, get_call_log(), "")
	s.template = "voice/rtblsection"
	s:option(DummyValue, "time", "Time")
	s:option(DummyValue, "direction", "Direction")
	s:option(DummyValue, "from", "From")
	s:option(DummyValue, "to", "To")
	s:option(DummyValue, "note", "Note")

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
