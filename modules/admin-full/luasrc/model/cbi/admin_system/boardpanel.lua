m = Map("boardpanel", "Board Panel")
s = m:section(NamedSection, "settings")
s.title = "Activate/deactivate hardware functions on board panel"
s.anonymous = true

sl = s:option(Flag, "status_led", "LEDs")
sl.rmempty = false

wifib = s:option(Flag, "wifibutton", "WiFi Button")
wifib.rmempty = false

wpsb = s:option(Flag, "wpsbutton", "WPS Button")
wpsb.rmempty = false

return m

