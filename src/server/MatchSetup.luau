local Setup={}
Setup.ARCADE_FEATURES_ENABLED=false
function Setup.abilities(mode) return mode=="Arcade" and Setup.ARCADE_FEATURES_ENABLED end
Setup.players={Practice=1,["1V1"]=2,["1V2"]=3,["2V2"]=4}
Setup.modes={Classic=true,Arcade=true,Chaos=true}
function Setup.valid(mode,map,modifier)
 if not Setup.modes[mode] or (map~="Rooftop" and map~="Moon") then return false end
 if mode=="Classic" then return modifier=="None" end
 if mode=="Chaos" then return modifier=="LowGravity" end
 return modifier=="None" or modifier=="LowGravity"
end
return Setup
