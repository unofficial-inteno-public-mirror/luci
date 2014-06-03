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

			entry({user, "services", "voice", "voice_voicemail"},
				arcombine(cbi("voice_voicemail"), cbi("voice_mailbox_details")),
				_("Voice Mail"), 7).leaf = true

			entry({user, "services", "voice", "voice_queues"},
				arcombine(cbi("voice_queues"), cbi("voice_queue_details")),
				_("Call Queues"), 8).leaf = true

			entry({user, "services", "voice", "voice_ivr"},
				arcombine(cbi("voice_ivr"), cbi("voice_ivr_details")),
				_("IVR"), 9).leaf = true

			entry({user, "services", "voice", "voice_ivr_details"},
				arcombine(cbi("voice_ivr_details"), cbi("voice_tone_selection"))
				).leaf = true

			entry({user, "services", "voice", "voice_opening_hours"},
				arcombine(cbi("voice_opening_hours"), cbi("voice_opening_hours_profile")),
				_("Opening Hours"), 10).leaf = true

			entry({user, "services", "voice", "voice_call_filters"},
				arcombine(cbi("voice_call_filters"), cbi("voice_call_filter_details")),
				_("Call Filters"), 11).leaf = true

			entry({user, "services", "voice", "voice_conference"},
				arcombine(cbi("voice_conference"), cbi("voice_conference_details")),
				_("Conference"), 12).leaf = true

			entry({user, "services", "voice", "voice_log"},	cbi("voice_log"),	"Call Log",		99)
			entry({user, "status", "voice"},			cbi("voice_status"),	"SIP Registration",	80)
		end
	end
end
