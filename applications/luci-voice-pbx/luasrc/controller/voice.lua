module("luci.controller.voice", package.seeall)

function index()
	local users = { "admin", "support", "user" }

	for k, user in pairs(users) do

		if user == "user"  then
			entry({user, "services", "voice"},			cbi("voice_log"),	"Voice",		80)
			entry({user, "status", "voice"},			cbi("voice_status"),	"SIP Registration",	80)
		else
			entry({user, "services", "voice"},			cbi("voice"),		"Voice",		80)
			entry({user, "services", "voice", "voice"},		cbi("voice"),		"Voice",		1)
			entry({user, "services", "voice", "voice_sip"},
				arcombine(cbi("voice_sip"), cbi("voice_sip_details")),
				_("SIP Providers"), 2).leaf = true

			entry({user, "services", "voice", "voice_sip_users"},
				arcombine(cbi("voice_sip_users"), cbi("voice_sip_user_details")),
				_("SIP Users"), 3).leaf = true

			entry({user, "services", "voice", "voice_brcm"},	cbi("voice_brcm"),	"Lines",		4)
			entry({user, "services", "voice", "voice_advanced"},	cbi("voice_advanced"),	"Advanced Settings",	5)
			entry({user, "services", "voice", "voice_dialplan"},	cbi("voice_dialplan"),	"Dialplan",		6)
			entry({user, "services", "voice", "voice_log"},	cbi("voice_log"),	"Call Log",		7).leaf = true
			entry({user, "status", "voice"},			cbi("voice_status"),	"SIP Registration",	80)
		end
	end
end
