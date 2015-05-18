m = Map("firewall",
        translate("Firewall - DMZ Host"),
        translate("Redirect all WAN ports to an internal host."))

s = m:section(NamedSection, "dmz", "dmz")
s.anonymous = false

dmz_host = s:option(Value, "host", translate("DMZ Host"))
dmz_host.datatype = "ipaddr"
dmz_host.rmempty = true

dmz_host:value("", translate("None"))
-- Add IPv4 address hints to selection list
luci.sys.net.ipv4_clients(function(ip, name)
    dmz_host:value(ip, ip .. " (" .. name .. ")")
end)

if TECUSER then
excp = s:option(Value, "exclude_ports", translate("Exclude Ports"))
excp.rmempty = true
end

return m

