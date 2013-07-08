--[[
    Copyright 2011 Iordan Iordanov <iiordanov (AT) gmail.com>

    This file is part of luci-pbx.

    luci-pbx is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    luci-pbx is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with luci-pbx.  If not, see <http://www.gnu.org/licenses/>.
]]--

module("luci.controller.pbx", package.seeall)

function index()
	entry({"admin", "services", "pbx"},                 cbi("pbx"),          "PBX",              80)
	entry({"admin", "services", "pbx", "pbx_google"},   cbi("pbx_google"),   "Google Accounts",   1)
	entry({"admin", "services", "pbx", "pbx_voip"},     cbi("pbx_voip"),     "SIP Accounts",      2)
	entry({"admin", "services", "pbx", "pbx_users"},    cbi("pbx_users"),    "User Accounts",     3)
	entry({"admin", "services", "pbx", "pbx_calls"},    cbi("pbx_calls"),    "Call Routing",      4)
	entry({"admin", "services", "pbx", "pbs_advanced"}, cbi("pbx_advanced"), "Advanced Settings", 5)
end
