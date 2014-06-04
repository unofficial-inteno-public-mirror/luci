--[[
Read SIP account status from ami_tool and present registration status for the SIP accounts
]]--

require("luci.json")
u = luci.model.uci:cursor()

function get_status()
	local status = {}
	ubus_data = luci.sys.exec("ubus call asterisk status")
	json_data = luci.json.decode(ubus_data)
	sip_data = json_data.sip

	u:foreach("voice_client", "sip_service_provider",
		function(sip_account)
			accountname = sip_account['.name']
			if not sip_account.enabled or sip_account.enabled ~= "1" then
				return
			end

			row = {
				title = sip_account.name,
				user = sip_data[accountname].username,
				domain = sip_data[accountname].domain,
				state = sip_data[accountname].state,
				refresh = tostring(sip_data[accountname].refresh_interval),
				regtime = sip_data[accountname].last_successful_registration
			}
			status[accountname] = row
		end
	)
	return status
end

m = SimpleForm("voice_status", "SIP Registration status", "Registration status of enabled SIP accounts")
m.reset = false
m.submit = false

-- Read registration status
status_ok, result = pcall(get_status)

if status_ok then
	-- Create a Table section
	s = m:section(Table, result, "")
	s:option(DummyValue, "title", "SIP Account")
	s:option(DummyValue, "user", "User")
	s:option(DummyValue, "domain", "Domain")
	s:option(DummyValue, "state", "Status")
	s:option(DummyValue, "refresh", "Registration interval (s)")
	s:option(DummyValue, "regtime", "Last registration")
else
	-- Reading of sip registration status failed
	s = m:section(SimpleSection)
	s:option(DummyValue, "Error", "Failed to read status")
end

return m
