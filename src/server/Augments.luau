-- Pure draft rules: one rarity roll, disjoint offers, server-validated selections.
local Augments={DURATION=20}
local archetypes={
 {"Fleet Foot", "speed", 0.08, "Move %d%% faster", "WIND"},
 {"Second Wind", "regen", 0.18, "Recover stamina %d%% faster", "PULSE"},
 {"Long Reach", "reach", 0.06, "Extend contact range by %d%%", "ORBIT"},
 {"Quick Reset", "dive", 0.08, "Reduce dive cooldown by %d%%", "WIND"},
 {"Light Steps", "speed", 0.07, "Move %d%% faster", "ORBIT"},
 {"Deep Breath", "regen", 0.20, "Recover stamina %d%% faster", "PULSE"},
 {"Wide Guard", "reach", 0.07, "Extend contact range by %d%%", "SHIELD"},
 {"Acrobat", "dive", 0.09, "Reduce dive cooldown by %d%%", "ORBIT"},
 {"Court Runner", "speed", 0.09, "Move %d%% faster", "WIND"},
 {"Endless Rhythm", "regen", 0.16, "Recover stamina %d%% faster", "PULSE"},
 {"Sweet Spot", "reach", 0.08, "Extend contact range by %d%%", "SHIELD"},
 {"Afterimage", "dive", 0.10, "Reduce dive cooldown by %d%%", "WIND"},
}
Augments.caps={speed=0.6,regen=1.5,reach=0.4,dive=0.5}
function Augments.roll(random)
 local roll=random:NextNumber()
 return roll<0.6 and 1 or roll<0.9 and 2 or 3
end
function Augments.deal(random,count)
 assert(count>=1 and count<=4,"Draft supports one to four players")
 local tier=Augments.roll(random)
 local pool={}
 for index=1,#archetypes do pool[index]=index end
 for index=#pool,2,-1 do
  local other=random:NextInteger(1,index)
  pool[index],pool[other]=pool[other],pool[index]
 end
 local offers={}
 for player=1,count do
  offers[player]={}
  for slot=1,3 do
   local index=pool[(player-1)*3+slot]
   local base=archetypes[index]
   local amount=base[3]*tier
   offers[player][slot]={id=tostring(tier)..":"..index,name=base[1],stat=base[2],amount=amount,
    description=string.format(base[4],math.floor(amount*100+0.5)),symbol=base[5],tier=tier}
  end
 end
 return tier,offers
end
function Augments.choose(offer,id,stats)
 if not offer or type(id)~="string" then return nil end
 for _,card in ipairs(offer) do
  if card.id==id then
   stats[card.stat]=math.min(Augments.caps[card.stat],(stats[card.stat] or 0)+card.amount)
   return card
  end
 end
 return nil
end
return Augments
