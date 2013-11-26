local dsp = require "luci.dispatcher"

m = Map ("voice_pbx", translate("Voice Settings"))

brcm = m:section(TypedSection, "brcm_advanced")
brcm.anonymous = true

return m
