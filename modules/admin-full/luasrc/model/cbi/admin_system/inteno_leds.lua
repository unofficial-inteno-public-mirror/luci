m = Map("leds", "LEDs")
s = m:section(NamedSection, "leds")
s.title = "Configure LEDs"
s.anonymous = true

sl = s:option(Flag, "enable", "Status LEDs")
sl.rmempty = false

return m
