Parental Control Tab
====================

Ticket #4419
------------
Parental control is mostly used by setting access during certain times so:
[Openwrt Wiki] is the way to go.
We just need to make a intuitive gui for it is this something you can look into
Simon? [Project site]

The link describes how to schedule internet access based on IP blocking.

### Dependencies

    iptables-mod-ipopt

This package is already in the iopsys build.

### Further development

  * Ability to put devices in a user group.
  * OUI names

UCI Config
----------

Graphical Interface
-------------------
### Extensive layout
This needs some kind of engine which recalculates the rules.

    Parental Control
    ================
    Global ParentShield (OpenDNS)
    -----------------------------
     ( ) Enable
     (o) Disable
    
    ---------------------------------------------------------------
    Access Schedule                                       --------
    ---------------                                      | Delete |
                                                          --------
    Host:                                   |Name (192.168.1.42) v|
    
    Weekday          Enable           Start time          Stop time
    -------          ------           ----------          ---------
    Monday            [x]             | 21:00 v|          |21:00 v|
    Tuesday           [x]             | 21:00 v|          |21:00 v|
    Wednesday         [x]             | 21:00 v|          |21:00 v|
    Thursday          [x]             | 21:00 v|          |21:00 v|
    Friday            [ ]             | 21:00 v|          |21:00 v|
    Saturday          [ ]             | 21:00 v|          |21:00 v|
    Sunday            [x]             | 21:00 v|          |21:00 v|
    ---------------------------------------------------------------
    
      -----
     | Add |
      -----

#### HTML Mockup
<code>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Parental control</title>
</head>
<body>
<table width="800px">
  <h2>Access Schedule
  <tr>
    <td colspan="2">Host
    <td colspan="2"><select id="start_time"><option value="192.168.1.42">Tank430s (192.168.1.42)</option></select>
</table>
<table width="800px">
  <tr>
    <td>Weekday
    <td>Enable
    <td>Start time
    <td>Stop time
  <tr>
    <td>Monday
    <td><input type="checkbox" name="mon"   value="mon"    checked>
    <td><select id="start_mon"><option value="22:00">22:00</option></select>
    <td><select id="stop_mon" ><option value="05:00">05:00</option></select>
  <tr>
    <td>Tuesday
    <td><input type="checkbox" name="tue"   value="tue"    checked>
    <td><select id="start_tue"><option value="22:00">22:00</option></select>
    <td><select id="stop_tue" ><option value="05:00">05:00</option></select>
  <tr>
    <td>Wednesday
    <td><input type="checkbox" name="wed"   value="wed"    checked>
    <td><select id="start_wed"><option value="22:00">22:00</option></select>
    <td><select id="stop_wed" ><option value="05:00">05:00</option></select>
  <tr>
    <td>Thursday
    <td><input type="checkbox" name="thu"   value="thu"    checked>
    <td><select id="start_thu"><option value="22:00">22:00</option></select>
    <td><select id="stop_thu" ><option value="05:00">05:00</option></select>
  <tr>
    <td>Friday
    <td><input type="checkbox" name="fri"   value="fri"    checked>
    <td><select id="start_fri"><option value="22:00">22:00</option></select>
    <td><select id="stop_fri" ><option value="05:00">05:00</option></select>
  <tr>
    <td>Saturday
    <td><input type="checkbox" name="sat"   value="sat"    checked>
    <td><select id="start_sat"><option value="22:00">22:00</option></select>
    <td><select id="stop_sat" ><option value="05:00">05:00</option></select>
  <tr>
    <td>Sunday
    <td><input type="checkbox" name="sun"   value="sun"    checked>
    <td><select id="start_sun"><option value="22:00">22:00</option></select>
    <td><select id="stop_sun" ><option value="05:00">05:00</option></select>
</table>
</body>
</html>
<code>

#### JSON datastructure
<pre>
<code>
{
    "ip": "192.168.1.100",
    "mac": "c8:be:19:d3:c5:d0",
    "days": [
        {
            "name": "mon",
            "enable": true,
            "start": "22:00",
            "stop": "05:00"
        },
        {
            "name": "tue",
            "enable": true,
            "start": "22:00",
            "stop": "05:00"
        },
        {
            "name": "wed",
            "enable": true,
            "start": "22:00",
            "stop": "05:00"
        },
        {
            "name": "thu",
            "enable": true,
            "start": "22:00",
            "stop": "05:00"
        },
        {
            "name": "fri",
            "enable": false,
            "start": "22:00",
            "stop": "05:00"
        },
        {
            "name": "sat",
            "enable": false,
            "start": "22:00",
            "stop": "05:00"
        },
        {
            "name": "sun",
            "enable": true,
            "start": "22:00",
            "stop": "05:00"
        }
    ]
}
</code>
</pre>

#### UCI datastructure
By using a seperate UCI config file, we can probably use cbi bindings in the
LuCI GUI.

<pre>
<code>
/etc/config/parental

config parental 'schedule'
	option name 'Simon'
	list address '192.168.1.19'
	list address '192.168.1.49'
	option start_mon '12:00'
	option stop_mon '12:00'
	option enable_mon true
	option start_tue '12:00'
	option stop_tue '12:00'
	option enable_tue true
	option start_wed '12:00'
	option stop_wed '12:00'
	option enable_wed true
	option start_thu '12:00'
	option stop_thu '12:00'
	option enable_thu true
	option start_fri '12:00'
	option stop_fri '12:00'
	option enable_fri false
	option start_sat '12:00'
	option stop_sat '12:00'
	option enable_sat false
	option start_sun '12:00'
	option stop_sun '12:00'
	option enable_sun true
</code>
</pre>

This will have to be translated to firewall rules, such as:
<pre>
<code>
/etc/config/firewall:

config rule 'parental'
	option src              lan
	option dest             wan
	option src_ip           192.168.1.27
	option start_time       21:00
	option stop_time        09:00
	option weekdays         'mon tue wed thu fri'
	option target           REJECT
</code>
</pre>

#### Algorithm for translating the formats
Moving from the calendar format in the web GUI to a format closer to the UCI
firewall rules, can be achieved with the following algorithm.

<pre>
<code>
function transform(tab)
    tab.days = filter(tab.days, function(day)
        return day.enable
    end)

    local rules = {}
    for _,ip in ipairs(tab.address) do
        for _,day in pairs(tab.days) do
            local rule = {}
            rule.start   = day.start
            rule.stop    = day.stop
            rule.days    = { day.name }
            rule.address = ip
            for k,d2 in ipairs(tab.days) do
                if d2 ~= day and d2.start == rule.start and d2.stop == rule.stop then
                    table.insert(rule.days, d2.name)
                    tab.days[k] = nil
                end
            end
            table.insert(rules, rule)
        end
    end

    return rules
end
</code>
</pre>

### Corresponding to UCI config

    Parental Control
    ================
    Global ParentShield (OpenDNS)
    -----------------------------
     ( ) Enable
     (o) Disable
    
    ---------------------------------------------------------------
    Access Schedule                                       --------
    ---------------                                      | Delete |
                                                          --------
    Host                      Start blocking        Stop blocking
    |Name (192.168.1.42) v|   |21:00 v|             |05:00 v|
    
    Monday  Tuesday  Wednesday  Thursday  Friday  Saturday  Sunday
     [x]     [x]      [x]        [x]       [ ]     [ ]       [x]
    ---------------------------------------------------------------
     
      -----
     | Add |
      -----

#### HTML Mockup
<code>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Table test</title>
</head>
<body>
<table width="800px">
  <h2>Access Schedule
  <tr>
    <td>Host
    <td>Start blocking
    <td>Stop blocking
  <tr>
    <td><select id="start_time"><option value="192.168.1.42">Tank430s (192.168.1.42)</option></select>
    <td><input type=text value="22:00">
    <td><input type=text value="05:00">
</table>
<table width="800px">
  <tr>
    <td>Monday
    <td>Tuesday
    <td>Wednesday
    <td>Thursday
    <td>Friday
    <td>Saturday
    <td>Sunday
  <tr>
    <td><input type="checkbox" name="monday"   value="monday"    checked>
    <td><input type="checkbox" name="tuesday"  value="tuesday"   checked>
    <td><input type="checkbox" name="wednesday"value="wednesday" checked>
    <td><input type="checkbox" name="thursday" value="thursday"  checked>
    <td><input type="checkbox" name="friday"   value="friday"           >
    <td><input type="checkbox" name="saturday" value="saturday"         >
    <td><input type="checkbox" name="sunday"   value="sunday"    checked>
</table>
</body>
</html>
<code>

    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <title>Table test</title>
    </head>
    <body>
    <table width="800px">
      <h2>Access Schedule
      <tr>
        <td>Host
        <td>Start blocking
        <td>Stop blocking
      <tr>
        <td><select id="start_time"><option value="192.168.1.42">Tank430s (192.168.1.42)</option></select>
        <td><input type=text value="22:00">
        <td><input type=text value="05:00">
    </table>
    <table width="800px">
      <tr>
        <td>Monday
        <td>Tuesday
        <td>Wednesday
        <td>Thursday
        <td>Friday
        <td>Saturday
        <td>Sunday
      <tr>
        <td><input type="checkbox" name="monday"    value="monday"    checked>
        <td><input type="checkbox" name="tuesday"   value="tuesday"   checked>
        <td><input type="checkbox" name="wednesday" value="wednesday" checked>
        <td><input type="checkbox" name="thursday"  value="thursday"  checked>
        <td><input type="checkbox" name="friday"    value="friday"           >
        <td><input type="checkbox" name="saturday"  value="saturday"         >
        <td><input type="checkbox" name="sunday"    value="sunday"    checked>
    </table>
    </body>
    </html>

### Alternative with simpler LuCI template

    Parental Control
    ================
    Global ParentShield (OpenDNS)
    -----------------------------
     ( ) Enable
     (o) Disable
    
    ---------------------------------------------------------------
    Access Schedule                                       --------
    ---------------                                      | Delete |
                                                          --------
    Host                                    |Name (192.168.1.42) v|
    Start time                                            |21:00 v|
    Stop time                                             |05:00 v|
    
    Day                                                     Enable
    ---                                                     ------
    Monday                                                   [x]
    Tuesday                                                  [x]
    Wednesday                                                [x]
    Thursday                                                 [x]
    Friday                                                   [ ]
    Saturday                                                 [ ]
    Sunday                                                   [x]
    ---------------------------------------------------------------
    
      -----
     | Add |
      -----

[Project site]: http://project.inteno.se/issues/4419
[Openwrt Wiki]: http://wiki.openwrt.org/doc/uci/firewall#block.access.to.the.internet.for.specific.ip.on.certain.times
