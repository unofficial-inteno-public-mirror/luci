m = Map("layer2_interface_vdsl", "VDSL", "Configure your VDSL connection")

ptm = m:section(TypedSection, "vdsl_interface", translate("PTM Bridges"),
		translate("PTM bridges expose encapsulated ethernet in ptm " ..
			"connections as virtual Linux network interfaces which can " ..
			"be used in interface creations"))

	ptm.addremove = true
	ptm.anonymous = true

	ptm.create = function(self, section)
		local sid = TypedSection.create(self, section)
		local max_unit = -1
		local ptmdevicename  
		local baseifname
		m.uci:foreach("layer2_interface_vdsl", "vdsl_interface",
			function(s)
				local u = tonumber(s.unit)
				if u ~= nil and u > max_unit then
					max_unit = u
				end
			end)
		ptmdevicename="ptm"..(max_unit +1)..".1"
		baseifname="ptm"..(max_unit +1)
		m.uci:set("layer2_interface_vdsl", sid, "unit", max_unit + 1)
		m.uci:set("layer2_interface_vdsl", sid, "ifname", ptmdevicename)
		m.uci:set("layer2_interface_vdsl", sid, "baseifname", baseifname)
		
		

		return sid
	end
	local system
	
	ptm:option(DummyValue, "_ptm", translate("PTM Device")).value =function(self, section)
	            return m.uci:get("layer2_interface_vdsl", section, "ifname")
		    end
	name    = ptm:option(Value, "name", translate("Interface Name"))
	name.rmempty = false	
	 dslat=ptm:option(ListValue, "dslat", translate("Select DSL Latency Path0 "))
	 dslat:value("1", translate("DSL Latency Path0"))
	 dslat:value("2", translate("DSL Latency Path1"))
	 dslat:value("1,2", translate("DSL Latency Path1&2"))
	 
	 --dslat2=ptm:option(Flag, "dslat", translate("Select DSL Latency Path1"))
	  --dslat2.default = 0
	    --dslat2.enabled =2
	ptmprio = ptm:option(ListValue, "ptmprio", translate("Select PTM Priority"))
	ptmprio:value("1", translate(" Normal Priority"))
	ptmprio:value("2", translate("High Priority (Preemption)"))
	
	 
	ptmprio = ptm:option(ListValue, "ipqos", translate("Select IP QoS Scheduler Algorithm"))
	ptmprio:value("1", translate("Strict Priority Precedence"))
	ptmprio:value("2", translate("Weighted Fair Queuing"))
	mbs = ptm:option(Value, "MPPAL", translate("MPAAL Group Precedence"))
	mbs.rmempty = false
	mbs:depends({ipqos="high"})
	ptm:option(Flag, "bridge",translate("Enter if device will be used in a bridge") )
	

	
return m -- returns the map




