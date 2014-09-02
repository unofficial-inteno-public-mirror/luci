local dsp = require "luci.dispatcher"
local vc = require "luci.model.cbi.voice.common"

m = Map("voice_client", translate("Music On Hold"))

vc.add_section("moh")
s = m:section(TypedSection, "moh", "MOH", "Upload a sound file to be played when a call is put on hold or placed in a queue")
s.anonymous = true
s.addremove = false
function s.filter(self, section)
	if section ~= "moh" then
		return nil
	end
	return section
end

upload = s:option(FileUpload, 'sound_file', 'Sound', "The sound file must be in GSM format with a sample rate of 8 kHz. Use <tt>sox source.wav -r 8000 -c 1 music.gsm</tt> to convert.")

return m
