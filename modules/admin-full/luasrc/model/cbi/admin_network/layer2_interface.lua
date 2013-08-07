local ubus = require "ubus".connect()
local specs=ubus:call("router", "quest", { info = "specs" })
ubus:close()
m = Map("layer2_interface", translate("xDSL Settings"), translate("xDSL Line settings and profiles")) 

s = m:section(NamedSection, "capabilities", translate("Capabilities")) -- Configure atm interface
s:tab("modulation", translate("Modulation"))
s:tab("profile", translate("VDSL Profile"))
s:tab("capabilities", translate("Capabilities"))
e = s:taboption("modulation",Flag, "GDmt", translate("G.Dmt"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "Glite", translate("G.lite"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "T1413", translate("T.1413"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "ADSL2", translate("ADSL2"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "AnnexL", translate("AnnexL"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "ADSL2plus", translate("ADSL2+"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "AnnexM", translate("AnnexM"))
e.enabled = "Enabled"
e.disabled = ""
e = s:taboption("modulation",Flag, "VDSL2", translate("VDSL2"))
e.enabled = "Enabled"
e.disabled = ""
if not specs then
        e = s:taboption("profile",Flag, "8a", translate("8a"))  
        e.enabled = "Enabled"                                    
        e.disabled = ""                                          
        e = s:taboption("profile",Flag, "8b", translate("8b"))  
        e.enabled = "Enabled"                                   
        e.disabled = ""                                         
        e = s:taboption("profile",Flag, "8c", translate("8c"))   
        e.enabled = "Enabled"                                    
        e.disabled = ""                                          
        e = s:taboption("profile",Flag, "8d", translate("8d"))      
        e.enabled = "Enabled"                                       
        e.disabled = ""                                             
        e = s:taboption("profile",Flag, "12a", translate("12a"))    
        e.enabled = "Enabled"                                    
        e.disabled = ""                                             
        e = s:taboption("profile",Flag, "12b", translate("12b"))    
        e.enabled = "Enabled"                                       
        e.disabled = ""                                             
        e = s:taboption("profile",Flag, "17a", translate("17a"))    
        e.enabled = "Enabled"                                        
        e.disabled = ""

else
        if specs.vdsl then
        e = s:taboption("profile",Flag, "8a", translate("8a"))
        e.enabled = "Enabled"
        e.disabled = ""
        e = s:taboption("profile",Flag, "8b", translate("8b"))
        e.enabled = "Enabled"
        e.disabled = ""
        e = s:taboption("profile",Flag, "8c", translate("8c"))
        e.enabled = "Enabled"
        e.disabled = ""
        e = s:taboption("profile",Flag, "8d", translate("8d"))
        e.enabled = "Enabled"
        e.disabled = ""
        e = s:taboption("profile",Flag, "12a", translate("12a"))
        e.enabled = "Enabled"
        e.disabled = ""
        e = s:taboption("profile",Flag, "12b", translate("12b"))
        e.enabled = "Enabled"
        e.disabled = ""
        e = s:taboption("profile",Flag, "17a", translate("17a"))
        e.enabled = "Enabled"
        e.disabled = ""
        end
end
e = s:taboption("capabilities",Flag, "US0", translate("US0"))
e.enabled = "on"
e.disabled = "off"

e = s:taboption("capabilities",Flag, "bitswap", translate("Bitswap"))
e.enabled = "on"
e.disabled = "off"
  if specs.vdsl then
    e = s:taboption("capabilities",Flag, "sra", translate("SRA"))
    e.enabled = "on"
    e.disabled = "off"
  end
return m	



