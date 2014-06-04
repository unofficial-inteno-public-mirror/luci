local dsp = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

m = Map ("voice_pbx", translate("Voice Settings"))

function remove_recording(self, section)
	nixio.fs.remove("/usr/lib/asterisk/recordings/" .. section)
	luci.http.redirect(luci.dispatcher.build_url("admin/services/voice/voice"))
end

number = m.uci:get("voice_pbx", "features", "record_message")

s = m:section(Table, vc.get_recordings(), "Recordings", "Call " .. number .. " to record a new message")
s.template = "cbi/tblsection"
s:option(DummyValue, "timestamp", "Timestamp")
s:option(DummyValue, "format", "Format")
btn = s:option(Button, "file", "Remove")
btn.write = remove_recording

s = m:section(TypedSection, "moh", "Music on hold", "Upload a sound file to be played when a call is put on hold or placed in a queue")
s.anonymous = true
s.addremove = false
upload = s:option(FileUpload, 'sound_file', 'Sound', "The sound file must be in GSM format with a sample rate of 8 kHz. Use <tt>sox source.wav -r 8000 -c 1 music.gsm</tt> to convert.")

return m
