m = Map("power_mgmt", "Power Management")
s = m:section(TypedSection, "power_mgmt", "Adjust power saving options for the router.")
s.anonymous = true

function has_avs()
    return luci.sys.exec("db get hw.board.hasBrcmAvs") == "1"
end

function insert_options(o, tab)
    for opt in ipairs(tab) do
        for k,v in pairs(tab[opt]) do
            o:value(k,v)
        end
    end
end

cpuspeed = s:option(ListValue, "cpuspeed", "CPU Speed")
cpuspeed.widget = "radio"
insert_options(cpuspeed, {
    { ["0"]   = "1/1 SYNC"},
    { ["1"]   = "full speed ASYNC"},
    { ["2"]   = "1/2 speed ASYNC"},
    { ["4"]   = "1/4 speed ASYNC"},
    { ["8"]   = "1/8 speed ASYNC"},
    { ["256"] = "1/8 ASYNC when entering wait, 1/1 SYNC otherwise"},
})

cpur4kwait = s:option(Flag, "cpur4kwait", "CPU r4k Wait", "Keeps CPU in sleep state without spinning.")
cpur4kwait.rmempty = false

sr = s:option(Flag, "sr", "DRAM Self-Refresh")
sr:depends("cpur4kwait", "1")
sr.rmempty = false

ethapd = s:option(Flag, "ethapd", "Ethernet Auto Power Down")
ethapd.rmempty = false

eee = s:option(Flag, "eee", "Energy Efficient Ethernet")
eee.rmempty = false

-- replace with db call for checking avs availability
if has_avs() then
    avs = s:option(ListValue, "avs", "Adaptive Voltage Scaling")
    avs.widget = "radio"
    insert_options(avs, {
        { ["on"]      = "On"},
        { ["off"]     = "Off"},
        { ["stopped"] = "Stopped"},
        { ["deep"]    = "Deep"},
    })
end

--[[ Additional information from pwrctl show
        local pwrshow = luci.sys.exec("pwrctl show")
        local pwrup   = pwrshow:match("Powered up:%s+(%d)")
        local pwrdown = pwrshow:match("Powered down:%s+(%d)")
        local avslog  = pwrshow:match("AVS Log Period %(sec%)%s+(%d)")
--]]

return m

