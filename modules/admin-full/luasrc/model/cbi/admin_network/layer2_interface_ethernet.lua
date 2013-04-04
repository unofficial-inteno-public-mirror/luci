local sys = require "luci.sys"
local net = require "luci.model.network".init()
eth = Map("layer2_interface_ethernet",
	translate("Ethernet WAN"),
	translate("Configure your Ethernet WAN connection"))


s = eth:section(NamedSection, "Wan","ethernet_interface",  translate("Ethernet WAN Interface"), translate("Decide what ethernet port should be used for WAN services"))
s.addremove = true

s:option(DummyValue, "_ptm", translate("Device")).value = function(self, section)
	            return eth.uci:get("layer2_interface_ethernet", section, "ifname")
		    end
name = s:option(Value, "name", translate("Interface Name"))
name.rmempty = false
--s.template  = "cbi/tblsection"

iface = s:option(ListValue, "baseifname", translate("Interface Base"))
local ifcs = net:get_upinterfaces()
		if ifcs then
			local _, ifn			
			for _, ifn in ipairs(ifcs) do
			  if ifn:name():match("^eth%d$")  then
			    iface:value(ifn:name(), translate(ifn:portname()..":"..ifn:name()))
			  end
			end    
		end

function iface.write(self, section, value)
	buildifname=value..".1"
	eth.uci:set("layer2_interface_ethernet", section, "ifname", buildifname)
	eth.uci:set("layer2_interface_ethernet", section, "baseifname", value)
end          

s:option(Flag, "bridge", translate("Enter if device will be used in a bridge"))

return eth
