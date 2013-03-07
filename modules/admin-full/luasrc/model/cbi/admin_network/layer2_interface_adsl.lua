m = Map("layer2_interface_adsl", "ADSL", "Configure your ADSL connection")

atm = m:section(TypedSection, "atm_bridge", translate("ATM Bridges"),
		translate("ATM bridges expose encapsulated ethernet in AAL5 " ..
			"connections as virtual Linux network interfaces which can " ..
			"be used in interface creations"))

	atm.addremove = true
	atm.anonymous = true

	atm.create = function(self, section)
		local sid = TypedSection.create(self, section)
		local max_unit = -1
		local atmdevicename
		local baseifname   
		m.uci:foreach("layer2_interface_adsl", "atm_bridge",
			function(s)
				local u = tonumber(s.unit)
				if u ~= nil and u > max_unit then
					max_unit = u
				end
			end)
		atmdevicename="atm"..(max_unit +1)..".1"
		baseifname="atm"..(max_unit +1)
		m.uci:set("layer2_interface_adsl", sid, "unit", max_unit + 1)
		m.uci:set("layer2_interface_adsl", sid, "ifname", atmdevicename)
		m.uci:set("layer2_interface_adsl", sid, "baseifname", baseifname)
		m.uci:set("layer2_interface_adsl", sid, "link_type", "EoA")
		m.uci:set("layer2_interface_adsl", sid, "vpi", 8)
		m.uci:set("layer2_interface_adsl", sid, "vci", 35)
		

		return sid
	end
	local system
	atm:tab("general", translate("General Setup"))
	atm:tab("advanced", translate("Advanced Settings"))
	--system= cfgvalue(m.uci:get("atmdev", "general", "atm-bridge"))
	 
	atm:taboption("general", DummyValue, "_atm", translate("ATM Device")).value =function(self, section)
	            return m.uci:get("layer2_interface_adsl", section, "ifname")
		    end
	 name    = atm:taboption("general", Value, "name", translate("Interface Name"))
	name.rmempty = false	      
	vpi    = atm:taboption("general", Value, "vpi", translate("ATM Virtual Path Identifier (VPI): [0-255]"))
	vpi.rmempty = false
	vci    = atm:taboption("general", Value, "vci", translate("ATM Virtual Channel Identifier (VCI): [32-65535]"))
	vci.rmempty = false
	
	
	link_type = atm:taboption("general", ListValue, "link_type", translate("Select DSL Link Type (EoA is for PPPoE, IPoE, and Bridge.)"))
	link_type:value("EoA", translate("EoA"))
	link_type:value("PPPoA", translate("PPPoA"))
	link_type:value("IPoA", translate("IPoA"))
	link_type.default ="EoA"
	encaps= atm:taboption("general", ListValue, "encapseoa", translate("Encapsulation mode"))
	encaps:value("llcsnap_eth", translate("LLC/SNAP-Bridging"))
	encaps:value("vcmux_eth", translate("VC/MUX"))
	encaps.default = "llcsnap_eth"
	encaps:depends({link_type="EoA"})  
	 
	encaps = atm:taboption("general", ListValue, "encapspppoa", translate("Encapsulation mode"))
	encaps:value("vcmux_pppoa", translate("VC/MUX"))
	encaps:value("llcencaps_ppp", translate("LLC/ENCAPSULATION"))
	encaps:depends({link_type="PPPoA"})  
	
	encaps= atm:taboption("general", ListValue, "encapsipoa", translate("Encapsulation mode"))
	encaps:value("llcsnap_rtip", translate("VC/MUX"))
	encaps:value("vcmux_ipoa", translate("LLC/SNAP-ROUTING"))
	encaps:depends({link_type="IPoA"})  
	
	atm:taboption("general",Flag, "bridge",translate("Enter if device will be used in a bridge") )
	
	atmtype = atm:taboption("advanced", ListValue, "atmtype", translate("Service Category"))
	atmtype:value("ubr", translate("UBR Without PCR"))
	atmtype:value("ubr_pcr", translate("UBR With PCR"))
	atmtype:value("cbr", translate("CBR"))
	atmtype:value("nrtvbr", translate("Non Realtime VBR"))
	atmtype:value("rtvbr", translate("Realtime VBR"))
	
	pcr = atm:taboption("advanced", Value, "pcr", translate("Hide <abbr title=\"Extended Service Set Identifier\"> Peak Cell Rate: [cells/s]</abbr>"))
	pcr:depends({atmtype="ubr_pcr"})
	pcr:depends({atmtype="cbr"})
	pcr:depends({atmtype="nrtvbr"})
	pcr:depends({atmtype="rtvbr"})
	pcr.rmempty = false
	
	scr = atm:taboption("advanced", Value, "scr", translate("Hide <abbr title=\"Extended Service Set Identifier\">Sustainable Cell Rate: [cells/s]</abbr>"))
	scr:depends({atmtype="nrtvbr"})
	scr:depends({atmtype="rtvbr"})
	scr.rmempty = false
	mbs = atm:taboption("advanced", Value, "mbs", translate("Hide <abbr title=\"Extended Service Set Identifier\">Maximum Burst Size: [cells]</abbr>"))
	mbs.rmempty = false
	mbs:depends({atmtype="nrtvbr"})
	mbs:depends({atmtype="rtvbr"})
	  
	
return m -- returns the map




