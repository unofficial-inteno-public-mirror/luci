--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: processes.lua 7025 2011-05-04 21:23:55Z jow $
]]--

local quest = require "luci.quest"

f = SimpleForm("processes", translate("Processes"))
f.reset = false
f.submit = false

f:section(SimpleSection).template  = "processes_status"

if luci.http.formvalue("advanced") == "1" and TECUSER then
	t = f:section(Table, luci.sys.process.list())
	t:option(DummyValue, "PID", translate("PID"))
	t:option(DummyValue, "USER", translate("Owner"))
	t:option(DummyValue, "COMMAND", translate("Command"))
	t:option(DummyValue, "%CPU", translate("CPU usage (%)"))
	t:option(DummyValue, "%MEM", translate("Memory usage (%)"))

	hup = t:option(Button, "_hup", translate("Hang Up"))
	hup.inputstyle = "reload"
	function hup.write(self, section)
		null, self.tag_error[section] = luci.sys.process.signal(section, 1)
	end

	term = t:option(Button, "_term", translate("Terminate"))
	term.inputstyle = "remove"
	function term.write(self, section)
		null, self.tag_error[section] = luci.sys.process.signal(section, 15)
	end

	kill = t:option(Button, "_kill", translate("Kill"))
	kill.inputstyle = "reset"
	function kill.write(self, section)
		null, self.tag_error[section] = luci.sys.process.signal(section, 9)
	end
else
	t = f:section(Table, { 1 })
	pid = t:option(DummyValue, "PID", translate( "Number of Running Processes"))
	cpu = t:option(DummyValue, "CPU", translate("CPU Usage"))
	pid.value = quest.processes
	cpu.value = quest.cpuload
end

return f
