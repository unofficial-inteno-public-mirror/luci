local dsp = require "luci.dispatcher"

m = Map ("voice_pbx", translate("Voice Settings"))

s = m:section(TypedSection, "moh", "Music on hold", "Upload a sound file to be played when a call is put on hold or placed in a queue")
s.anonymous = true
s.addremove = false
upload = s:option(FileUpload, 'sound_file', 'Sound', "The sound file must be in GSM format with a sample rate of 8 kHz. Use <tt>sox source.wav -r 8000 -c 1 music.gsm</tt> to convert.")

return m
