--[[
Read SIP account status from asterisk and present registration status for the SIP accounts
]]--

require("luci.json")
u = luci.model.uci:cursor()

function get_status()
	local status = {}

	sip_registry = luci.sys.exec("asterisk -rx 'sip show registry'")
	ubus_data = luci.sys.exec("ubus call asterisk sip")
	json_data = luci.json.decode(ubus_data)

	lines = string.split(sip_registry, "\n")
	for _, line in ipairs(lines) do
		host, port = line:sub(1,40):match("^%s*(sip%d+):(%d+)%s*$")
		if host then
			dnsmgr = line:sub(41, 47):match("^%s*(.-)%s*$")
			acc_user = line:sub(48, 62):match("^%s*(.-)%s*$")
			acc_refresh = line:sub(63, 70):match("^%s*(.-)%s*$")
			acc_state = line:sub(71, 91):match("^%s*(.-)%s*$")
			acc_regtime = line:sub(92):match("^%s*(.-)%s*$")

			acc_name = u:get("voice_client", host, "name")
			acc_domain = u:get("voice_client", host, "domain")
			
			if json_data then
				acc_regtime = json_data[host].last_registration
			end

			if acc_state == "Registered" then
				acc_state = "Yes"
			else
				acc_state = string.format("No (%s)", acc_state)
			end

			row = {
				title = acc_name,
				user = acc_user,
				domain = acc_domain,
				state = acc_state,
				refresh = acc_refresh,
				regtime = acc_regtime
			}
			status[host] = row
		end
	end
	return status
end

m = SimpleForm("voice_status", "SIP Registration status", "Registration status of enabled SIP accounts")
m.reset = false
m.submit = false

-- Create a Table section
s = m:section(Table, get_status(), "")
s:option(DummyValue, "title", "SIP Account")
s:option(DummyValue, "user", "User")
s:option(DummyValue, "domain", "Domain")
s:option(DummyValue, "state", "Registered")
s:option(DummyValue, "refresh", "Registration interval (s)")
s:option(DummyValue, "regtime", "Last registration")

return m
