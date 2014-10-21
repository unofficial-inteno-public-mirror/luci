local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- returns a copy of a table
function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-- filter(function, table)
-- e.g: filter(is_even, {1,2,3,4}) -> {2,4}
function filter(tbl, func)
    local newtbl= {}
    for i,v in pairs(tbl) do
        if func(v) then
            newtbl[i]=v
        end
    end
    return newtbl
end

function convert_to_utc(time)
    local cmd = "date -d@$( echo $(( $(date -d " .. time .. " +%s) + $(echo $(( $(date +%s -d '00:00') - $(date  +%s -d '00:00' --utc))))))) +%H:%M"
    return sys.exec(cmd)
end

function transform(tab)
    tab.days = filter(tab.days, function(day) return day.enable end)

    local rules = {}
    for _,day in pairs(tab.days) do
        local rule = {
            parental = "1",
            src = "lan",
            dest = "wan",
            target = "REJECT",
            start_time = day.start,
            stop_time = day.stop,
            weekdays = day.name
        }
        rule.start_time = convert_to_utc(rule.start_time)
        rule.stop_time  = convert_to_utc(rule.stop_time)
        -- add identical day(s) to the same rule
        for k,d in pairs(tab.days) do
            if d ~= day
                and d.start == rule.start_time and d.stop == rule.stop_time then
                rule.weekdays = rule.weekdays .. " " .. d.name
                tab.days[k] = nil
            end
        end

        table.insert(rules, rule)
    end

    return rules
end

-- create rules for every address
function addaddr(tab, addr)
    local new = {}
    for i=1, #addr do
        for j=1, #tab do
            tmp = deepcopy(tab[j])
            tmp.src_mac = addr[i]
            table.insert(new, tmp)
        end
    end
    return new
end

local times = {
    "00:00",
    "01:00",
    "02:00",
    "03:00",
    "04:00",
    "05:00",
    "06:00",
    "07:00",
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
    "20:00",
    "21:00",
    "22:00",
    "23:00",
}

function insert_options(o, tab, offset)
    for i=0, #tab do
        local pos = (i+offset) % #tab + 1
        local t = tab[pos]
        o.default = o.default or t
        o:value(t,t)
    end
end

m = Map("parental", translate("Parental Control"))

s = m:section(TypedSection, "parental", translate("Access Schedule"), translate("Place time-limits on certain users internet access."))
s.template = "cbi/tsection"
s.addremove = true
s.anonymous = true

o = s:option(Value, "name", "Name")
o.optional = false

o = s:option(DynamicList, "address", translate("Blocked host"), translate("Host will be blocked based on the MAC address."))
luci.sys.net.mac_clients(function(mac, name)
    o:value(mac, "%s (%s)" %{ mac, name })
    o.default = o.default or o
end)
o.rmempty = false
o.optional = false

-- weekdays
o = s:option(Flag,  "enable_mon", "Monday")
o = s:option(Value, "start_mon",  "Start"); insert_options(o, times, 22)
o:depends("enable_mon", "1")
o = s:option(Value, "stop_mon",   "Stop");  insert_options(o, times, 6)
o:depends("enable_mon", "1")

o = s:option(Flag,  "enable_tue", "Tuesday")
o = s:option(Value, "start_tue",  "Start"); insert_options(o, times, 22)
o:depends("enable_tue", "1")
o = s:option(Value, "stop_tue",   "Stop");  insert_options(o, times, 6)
o:depends("enable_tue", "1")

o = s:option(Flag,  "enable_wed", "Wednesday")
o = s:option(Value, "start_wed",  "Start"); insert_options(o, times, 22)
o:depends("enable_wed", "1")
o = s:option(Value, "stop_wed",   "Stop");  insert_options(o, times, 6)
o:depends("enable_wed", "1")

o = s:option(Flag,  "enable_thu", "Thursday")
o = s:option(Value, "start_thu",  "Start"); insert_options(o, times, 22)
o:depends("enable_thu", "1")
o = s:option(Value, "stop_thu",   "Stop");  insert_options(o, times, 6)
o:depends("enable_thu", "1")

o = s:option(Flag,  "enable_fri", "Friday")
o = s:option(Value, "start_fri",  "Start"); insert_options(o, times, 22)
o:depends("enable_fri", "1")
o = s:option(Value, "stop_fri",   "Stop");  insert_options(o, times, 6)
o:depends("enable_fri", "1")

o = s:option(Flag,  "enable_sat", "Saturday")
o = s:option(Value, "start_sat",  "Start"); insert_options(o, times, 22)
o:depends("enable_sat", "1")
o = s:option(Value, "stop_sat",   "Stop");  insert_options(o, times, 6)
o:depends("enable_sat", "1")

o = s:option(Flag,  "enable_sun", "Sunday")
o = s:option(Value, "start_sun",  "Start"); insert_options(o, times, 22)
o:depends("enable_sun", "1")
o = s:option(Value, "stop_sun",   "Stop");  insert_options(o, times, 6)
o:depends("enable_sun", "1")

function convert_schedule(s)
    return {
        name = s.name,
        address = s.address,
        days = {
            {
                name   = "mon",
                enable = s.enable_mon,
                start  = s.start_mon,
                stop   = s.stop_mon,
            }, {
                name   = "tue",
                enable = s.enable_tue,
                start  = s.start_tue,
                stop   = s.stop_tue,
            }, {
                name   = "wed",
                enable = s.enable_wed,
                start  = s.start_wed,
                stop   = s.stop_wed,
            }, {
                name   = "thu",
                enable = s.enable_thu,
                start  = s.start_thu,
                stop   = s.stop_thu,
            }, {
                name   = "fri",
                enable = s.enable_fri,
                start  = s.start_fri,
                stop   = s.stop_fri,
            }, {
                name   = "sat",
                enable = s.enable_sat,
                start  = s.start_sat,
                stop   = s.stop_sat,
            }, {
                name   = "sun",
                enable = s.enable_sun,
                start  = s.start_sun,
                stop   = s.stop_sun,
            }
        }
    }
end

function handle_schedule(s)
    local converted   = convert_schedule(s)
    local transformed = transform(converted)
    local complete    = addaddr(transformed, converted.address)
    for k,v in ipairs(complete) do
        local name = uci:section("firewall", "rule", nil, v)
    end
end

m.on_after_commit = function(self)
    -- delete previous rules before recreating them from parental config
    uci:delete_all("firewall", "rule", function(s) return s.parental == "1" end)

    uci:foreach("parental", "parental", function(s)
        handle_schedule(s)
    end)
    uci:save("firewall")
    uci:commit("firewall")
    luci.sys.exec("fw3 reload")
end

return m

