m = Map("btle_alarm", translate("Bluetooth LE \"Pairing\""), translate("Please enter the bluetooth mac aaddress in the form below")) -- cbi_file is the config file in /etc/config
d = m:section(TypedSection, "info", "")  -- info is the section called info in cbi_file
a = d:option(Value, "mac", "Mac Address"); a.optional=false; a.rmempty = false;  -- name is the option in the cbi_file
return m
