local dsp = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

m = Map ("voice", translate("Sounds"))

function remove_recording(self, section)
	for i,v in pairs(vc.get_recordings()) do
		if section == i then
			nixio.fs.remove("/usr/lib/asterisk/recordings/" .. v["file"])
			break
		end
	end
	luci.http.redirect(luci.dispatcher.build_url("admin/services/voice/voice"))
end

number = m.uci:get("voice", "custom_dialplan", "record_message_extension")
if not number then
	number = "#99999"
	m.uci:set("voice", "custom_dialplan", "record_message_extension", number)
	m.uci:commit("voice")
end
description = "Call " .. number .. " to record a new message"

s = m:section(Table, vc.get_recordings(), "Recordings", description)
s.template = "cbi/tblsection"
s:option(DummyValue, "timestamp", "Timestamp")
s:option(DummyValue, "format", "Format")
btn = s:option(Button, "file", "Remove")
btn.write = remove_recording

s = m:section(Table, vc.get_custom_sounds(), "Custom Sounds")
s.template = "cbi/tblsection"
s:option(DummyValue, "name", "Name")
s:option(DummyValue, "format", "Format")
s.anonymous = true
s.addremove = false

vc.add_section("custom_sounds")
s = m:section(TypedSection, "custom_sounds", "Upload Custom Sound", "Upload custom sound-pack to be used for IVRs")
s.anonymous = true
s.addremove = false
function s.filter(self, section)
	if section ~= "custom_sounds" then
		return nil
	end
	return section
end

upload = s:option(FileUpload, "sound_pack", "Sound", "The files must be contained in a single directory called custom and compressed as <strong>tar.gz</strong>")

vc.add_section("language")
s = m:section(TypedSection, "language", "Language", "Upload sound files to be used for various voice services")
s.anonymous = true
s.addremove = false
function s.filter(self, section)
	if section ~= "language" then
		return nil
	end
	return section
end

upload = s:option(FileUpload, 'voice_pack', 'Voice-pack', "The voice-pack must contain a single directory named <strong>sounds</strong> and compressed as <strong>tar.gz</strong>")

return m
