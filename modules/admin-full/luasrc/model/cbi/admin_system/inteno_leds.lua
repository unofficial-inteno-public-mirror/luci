m = Map("boardpanel", "LEDs")
s = m:section(NamedSection, "settings")
s.title = "Configure LEDs"
s.anonymous = true

sl = s:option(Flag, "status_led", "Status LEDs")
sl.rmempty = false

return m
