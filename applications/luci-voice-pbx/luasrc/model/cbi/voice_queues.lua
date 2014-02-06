--[[
LuCI - Lua Configuration Interface

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

-- http://luci.subsignal.org/trac/browser/luci/trunk/applications/luci-radvd/luasrc/model/cbi/radvd.lua?rev=6
local ds = require "luci.dispatcher"

m = Map ("voice_pbx", "Call Queues")
s = m:section(TypedSection, "queue")
s.template = "voice_pbx/tblsection_refresh"
s.anonymous = true
s.addremove = true
s.extedit = ds.build_url("admin/services/voice/voice_queue/%s")

-- This function is called when a new queue should be created i.e. when
-- user presses the "Add" button. We create a new section, name it, and
-- proceed to detailed editor.
function s.create(self, section)
	if section_count < 8 then
		data = { name = "New Call Queue" }
		newQueue = m.uci:section("voice_pbx", "queue", nil, data)
		luci.http.redirect(s.extedit % newQueue)
	end
end

-- Called when a queue is being deleted
function s.remove(self, section)
	TypedSection.remove(self, section)
end

queue_name = s:option(DummyValue, "name", "Queue")

extension = s:option(DummyValue, "extension", "Extension")

e = s:option(Flag, "enabled", "Enabled")
e.default = 0

return m
