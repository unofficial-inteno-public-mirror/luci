local dsp = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

m = Map ("voice_pbx", translate("Voice Settings"))

function remove_recording(self, section)
	for i,v in pairs(vc.get_recordings()) do
		if section == i then
			nixio.fs.remove("/usr/lib/asterisk/recordings/" .. v["file"])
			break
		end
	end
	luci.http.redirect(luci.dispatcher.build_url("admin/services/voice/voice"))
end

number = m.uci:get("voice_pbx", "features", "record_message")
local description
if number then
	description = "Call " .. number .. " to record a new message"
else
	description = "No extension configured for recording messages"
end

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

s = m:section(TypedSection, "custom_sounds", "Upload Custom Sound", "Upload custom sound-pack to be used for IVRs")
s.anonymous = true
s.addremove = false
upload = s:option(FileUpload, "sound_pack", "Sound", "The files must be contained in a single directory called custom and compressed as <strong>tar.gz</strong>")

s = m:section(TypedSection, "moh", "Music on hold", "Upload a sound file to be played when a call is put on hold or placed in a queue")
s.anonymous = true
s.addremove = false
upload = s:option(FileUpload, 'sound_file', 'Sound', "The sound file must be in GSM format with a sample rate of 8 kHz. Use <tt>sox source.wav -r 8000 -c 1 music.gsm</tt> to convert.")

return m
