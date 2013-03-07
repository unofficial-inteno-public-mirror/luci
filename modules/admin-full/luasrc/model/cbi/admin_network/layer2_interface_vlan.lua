local net = require "luci.model.network".init()
m = Map("layer2_interface_vlan",
	translate("VLAN"),
	translate("Configure your VLAN connection"))


local bit = require "bit"

s = m:section(TypedSection, "vlan_interface",  translate("802.1Q Bridges"), translate("802.1Q bridges expose encapsulated ethernet in vlan connections as virtual Linux network interfaces which can be used in interface creations"))
s.addremove = true
s.anonymous = true
s:option(DummyValue, "_ptm", translate("Device")).value =function(self, section)
	            return m.uci:get("layer2_interface_vlan", section, "ifname")
		    end
name    = s:option(Value, "name", translate("Interface Name"))
	name.rmempty = false
--s.template  = "cbi/tblsection"

iface = s:option(ListValue, "baseifname", translate("Layer 2 Interface"))
local ifcs = net:get_layer2interfacesbase()
		if ifcs then
			local _, ifn
			for _, ifn in ipairs(ifcs) do
				iface:value(ifn:name(), translate(ifn:layer2name()))
			end
		end	

t = s:option(Value, "vlan8021q", translate("Enter 802.1Q VLAN ID [0-4094]:"))

function iface.write(self, section, value)
		local vlan=t:formvalue(section)
		buildifname=value.."."..vlan
		m.uci:set("layer2_interface_vlan", section, "ifname",buildifname )
		m.uci:set("layer2_interface_vlan", section, "baseifname",value )
                end 
n = s:option(Value, "vlan8021p",translate("Enter 802.1P Priority [0-7]:") )
n = s:option(Flag, "bridge",translate("Enter if device will be used in a bridge") )

return m
