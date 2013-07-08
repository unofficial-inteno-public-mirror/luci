--[[
Read SIP account status from /var/state/
and present registration status for the SIP accounts
]]--

u = luci.model.uci:cursor()
us = luci.model.uci:cursor_state()

-- Get registration status
function get_status()
	local status = {}
	u:foreach ("voice_client", "sip_service_provider", 
		function(s1)
			if s1.enabled == "1" then
				local s1registered = us:get("asterisk", s1['.name'], "sip_registry_registered")
				if not s1registered then
					s1registered = "unknown"
				end

				local s1request_sent = us:get("asterisk", s1['.name'], "sip_registry_request_sent")
				if not s1request_sent then
					s1request_sent = "unknown"
				end

				row = {
					title = s1.name,
					user = s1.user,
					domain = s1.domain,
					registered = s1registered,
					request_sent = s1request_sent
				}
				status[s1['.name']] = row
			end
		end
	)
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
s:option(DummyValue, "registered", "Registered")
s:option(DummyValue, "request_sent", "Registration request sent")

return m
