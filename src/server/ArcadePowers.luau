-- Shared eight-power engine: Arcade deck offers and random Chaos stacks.
local Deck=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ArcadeDeck"))
local Arcade={}
Arcade.__index=Arcade
function Arcade.new(random)
 return setmetatable({random=random or Random.new(),players={},hazards={},zeroUntil=0,glowUntil=0},Arcade)
end
function Arcade:reset()
 for _,hazard in ipairs(self.hazards) do if hazard.part then hazard.part:Destroy() end end
 table.clear(self.players); table.clear(self.hazards); self.zeroUntil=0; self.glowUntil=0
 self.remaining=self.random:NextInteger(2,4)
 self.chaosElapsed=0; self.chaosNext=4; self.chaosEvent=nil
 self.chaosGravity=1
end
function Arcade:data(player)
 if not self.players[player] then self.players[player]={slots={},effects={},pending={},levels={},chaosTimers={}} end
 return self.players[player]
end
function Arcade:empty(player,now)
 local data=self:data(player)
 local slots=data.slots
 for index=1,2 do
  local slot=slots[index]
  if slot and slot.readyAt and now>=slot.readyAt then
   if (slot.charges or 0)>0 then slot.readyAt=nil;slot.activeUntil=nil;slot.duration=nil
   else slots[index]=nil end
  end
  if not slots[index] and #data.pending>0 then
   local id=table.remove(data.pending,1);slots[index]={id=id,charges=1}
   for i=#data.pending,1,-1 do if data.pending[i]==id then slots[index].charges+=1;table.remove(data.pending,i) end end
  end
 end
 for index=1,2 do if not slots[index] then return index end end
end
function Arcade:offer(player,ids,now)
 if not Deck.validate(ids) or not self:empty(player,now) then return nil end
 local cards={}
 for _,id in ipairs(ids) do table.insert(cards,Deck.find(id)) end
 -- Shuffle without changing the selected deck.
 for i=#cards,2,-1 do local j=self.random:NextInteger(1,i); cards[i],cards[j]=cards[j],cards[i] end
 return cards
end
function Arcade:chaosOffer()
 local cards=table.clone(Deck.cards)
 for i=#cards,2,-1 do local j=self.random:NextInteger(1,i); cards[i],cards[j]=cards[j],cards[i] end
 return {cards[1],cards[2],cards[3]}
end
function Arcade:chaosUpgradeOffer(player)
 local levels=self:data(player).levels
 local cards={}
 for _,base in ipairs(Deck.cards) do
  if (levels[base.id] or 0)<Deck.CHAOS_MAX_LEVEL then table.insert(cards,Deck.chaosCard(base.id,levels[base.id])) end
 end
 for i=#cards,2,-1 do local j=self.random:NextInteger(1,i); cards[i],cards[j]=cards[j],cards[i] end
 local offer={}
 for i=1,math.min(3,#cards) do offer[i]=cards[i] end
 return #offer>0 and offer or nil
end
function Arcade:chooseChaos(player,offer,id)
 if type(offer)~="table" or type(id)~="string" then return nil end
 local levels=self:data(player).levels
 for _,candidate in ipairs(offer) do
  if candidate.id==id and candidate.chaosUpgrade and Deck.find(id) then
   local current=levels[id] or 0
   if current>=Deck.CHAOS_MAX_LEVEL or current~=candidate.previousLevel then return nil end
   local card=Deck.chaosCard(id,current)
   levels[id]=card.level
   return card
  end
 end
end
function Arcade:choose(player,offer,id,now,stack)
 local index=self:empty(player,now)
 if (not index and not stack) or type(offer)~="table" then return nil end
 for _,card in ipairs(offer) do
  if card.id==id and Deck.find(id) then
   local data=self:data(player)
   if stack then
    for slot,existing in pairs(data.slots) do
     if existing.id==id then existing.charges=(existing.charges or 0)+1;return card,slot end
    end
   end
   if index then data.slots[index]={id=id,charges=1}
   else table.insert(data.pending,id) end
   return card,index
  end
 end
end
function Arcade:rally()
 self.remaining=(self.remaining or self.random:NextInteger(2,4))-1
 if self.remaining>0 then return false end
 self.remaining=self.random:NextInteger(2,4); return true
end
function Arcade:effect(player,id,now)
 return now<(self:data(player).effects[id] or 0)
end
function Arcade:reach(player,now)
 local data=self:data(player)
 return Deck.chaosValues(data.levels).reach*(data.chaosShrink or 1)
  *(self:effect(player,"bigPaddle",now) and 1.75 or 1)*(self:effect(player,"smallPaddle",now) and 0.5 or 1)
end
function Arcade:speed(player,now)
 return Deck.chaosValues(self:data(player).levels).speed*(self:effect(player,"speedCleats",now) and 1.4 or 1)
end
function Arcade:swingScale(player,now)
 return Deck.chaosValues(self:data(player).levels).swing*(self:effect(player,"speedCleats",now) and Deck.SPEED_SWING_SCALE or 1)
end
function Arcade:gravity(now) return math.min(self.chaosGravity or 1,now<self.zeroUntil and 0.4 or 1) end
function Arcade:arm(player,index,now)
 if type(index)~="number" or index%1~=0 or index<1 or index>2 then return nil end
 self:empty(player,now)
 local slot=self:data(player).slots[index]
 if not slot or slot.readyAt or (slot.charges or 0)<=0 then return nil end
 slot.armed=not slot.armed
 return slot.armed
end
function Arcade:clearArmed(player)
 if player then
  local data=self.players[player]
  if data then for _,slot in pairs(data.slots) do slot.armed=nil end end
 else
  for p in pairs(self.players) do self:clearArmed(p) end
 end
end
function Arcade:activateArmed(player,now,side,opponents,root,world,chaos)
 local activated={}
 local data=self.players[player]
 if not data then return activated end
 for index=1,2 do
  local slot=data.slots[index]
  if slot and slot.armed then
   slot.armed=nil
   local card=self:activate(player,index,now,side,opponents,root,world,chaos)
   if card then table.insert(activated,card) end
  end
 end
 return activated
end
function Arcade:activate(player,index,now,side,opponents,root,world,chaos)
 if type(index)~="number" or index%1~=0 or index<1 or index>2 then return nil end
 self:empty(player,now)
 local data=self:data(player)
 local slot=data.slots[index]
 if not slot or slot.readyAt then return nil end
 slot.armed=nil
 local card=Deck.find(slot.id)
 slot.charges=math.max(0,(slot.charges or 1)-1)
 local duration=card.duration==0 and 15 or card.duration
 slot.cooldownDuration=chaos and Deck.CHAOS_COOLDOWN or Deck.COOLDOWN
 slot.activeUntil=now+duration; slot.readyAt=slot.activeUntil+slot.cooldownDuration; slot.duration=duration
 if card.id~="smallPaddle" then data.effects[card.id]=slot.activeUntil end
 if card.id=="smallPaddle" then
  for _,opponent in ipairs(opponents) do self:data(opponent).effects.smallPaddle=now+Deck.SMALL_PADDLE_SECONDS end
 elseif card.id=="zeroG" then self.zeroUntil=math.max(self.zeroUntil,slot.activeUntil)
 elseif card.id=="glowBall" then self.glowUntil=math.max(self.glowUntil,slot.activeUntil)
 elseif card.id=="dropPickles" or card.id=="slipStream" then
  for i=1,(card.id=="dropPickles" and 3 or 1) do
   local position=Vector3.new(math.clamp(root.Position.X+(i-2)*6,-16,16),181.4,-side*self.random:NextNumber(12,32))
   local part=Instance.new("Part"); part.Name=card.name; part.Anchored=true; part.CanCollide=false; part.CanTouch=false
   part.Material=Enum.Material.Neon; part.Color=card.id=="dropPickles" and Color3.fromRGB(149,255,63) or Color3.fromRGB(255,221,60)
   part.Size=card.id=="dropPickles" and Vector3.new(1.5,0.5,3) or Vector3.new(10,0.12,12)
   part.Position=position; part.Transparency=card.id=="dropPickles" and 0.1 or 0.45; part.Parent=world
   table.insert(self.hazards,{part=part,position=position,side=-side,expires=slot.activeUntil,kind=card.id,touched={}})
  end
 end
 return card
end
function Arcade:heatTarget(player,now,opponentPositions,side)
 local data=self:data(player)
 local level=data.levels.heatseeker or 0
 if level>0 then
  if now<(data.chaosHeatReadyAt or 0) then return nil end
  data.chaosHeatReadyAt=now+Deck.chaosValues(data.levels).heatInterval
 elseif not self:effect(player,"heatseeker",now) then return nil end
 data.effects.heatseeker=0
 for _,slot in pairs(data.slots) do
  if slot.id=="heatseeker" and slot.activeUntil and slot.activeUntil>now then slot.activeUntil=now; slot.readyAt=now+(slot.cooldownDuration or Deck.COOLDOWN) end
 end
 local best,bestDistance
 for _,x in ipairs({-17,17}) do
  local target=Vector3.new(x,181.7,-side*35); local nearest=math.huge
  for _,position in ipairs(opponentPositions) do nearest=math.min(nearest,(target-position).Magnitude) end
  if not best or nearest>bestDistance then best=target; bestDistance=nearest end
 end
 return best
end
function Arcade:touch(key,side,position,now)
 local effects=self:data(key).effects
 for _,hazard in ipairs(self.hazards) do
  if now<hazard.expires and hazard.side==side and not hazard.touched[key] then
   local offset=Vector3.new(position.X-hazard.position.X,0,position.Z-hazard.position.Z)
   local inZone=hazard.halfSize and math.abs(offset.X)<=hazard.halfSize and math.abs(offset.Z)<=hazard.halfSize
    or not hazard.halfSize and offset.Magnitude<=Deck.HAZARD_RADIUS
   if inZone then
    hazard.touched[key]=true; effects.slide=now+Deck.PICKLE_RECOVERY
    effects.slideDirection=offset.Magnitude>0.1 and offset.Unit or Vector3.new(1,0,0)
   end
  end
 end
 return now<(effects.slide or 0),effects.slideDirection
end
function Arcade:update(now)
 for i=#self.hazards,1,-1 do
  if now>=self.hazards[i].expires then self.hazards[i].part:Destroy(); table.remove(self.hazards,i) end
 end
end
function Arcade:chaosGift(player,now)
 local offer=self:chaosOffer()
 return self:choose(player,offer,offer[1].id,now,true)
end

-- Permanent levels remain between rallies; automatic hazards advance only in live play.
function Arcade:chaosUpdate(dt,now,participants,world,live)
 self.chaosGravity=1
 for _,entry in ipairs(participants) do
  local data=self:data(entry.player)
  local values=Deck.chaosValues(data.levels)
  self.chaosGravity=math.min(self.chaosGravity,values.gravity)
  data.chaosShrink=1
  for _,enemy in ipairs(participants) do
   if enemy.side~=entry.side then data.chaosShrink=math.min(data.chaosShrink,Deck.chaosValues(self:data(enemy.player).levels).shrink) end
  end
  if not live then continue end
  for _,id in ipairs({"dropPickles","slipStream"}) do
   local level=data.levels[id] or 0
   if level==0 then continue end
   local elapsed=(data.chaosTimers[id] or 0)+math.max(0,dt)
   local interval=id=="dropPickles" and values.pickleInterval or values.slipInterval
   data.chaosTimers[id]=elapsed
   if elapsed<interval then continue end
   data.chaosTimers[id]=0
   local count=id=="dropPickles" and values.pickleCount or 1
   for _=1,count do
    local position=Vector3.new(self.random:NextNumber(-14,14),181.4,-entry.side*self.random:NextNumber(16,34))
    local part=Instance.new("Part"); part.Name="Chaos "..Deck.find(id).name
    part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.Material=Enum.Material.Neon
    part.Color=id=="dropPickles" and Color3.fromRGB(149,255,63) or Color3.fromRGB(255,221,60)
    part.Size=id=="dropPickles" and Vector3.new(1.5,0.5,3) or Vector3.new(values.slipSize,0.12,values.slipSize)
    part.Position=position; part.Transparency=id=="dropPickles" and 0.1 or 0.45; part.Parent=world
    table.insert(self.hazards,{part=part,position=position,side=-entry.side,expires=now+6,kind=id,
     halfSize=id=="slipStream" and values.slipSize/2 or nil,touched={}})
   end
  end
 end
end

-- Tick only during live Chaos rallies; one shared event affects both teams.
function Arcade:chaosStep(dt,now,participants,world)
 self.chaosElapsed=(self.chaosElapsed or 0)+math.max(0,dt)
 if self.chaosElapsed<(self.chaosNext or 4) or #participants==0 then return nil end
 local events={
  {id="speedCleats",name="SPEED FRENZY",detail="Everyone moves faster"},
  {id="bigPaddle",name="GIANT PADDLES",detail="Everyone gets extra reach"},
  {id="zeroG",name="GRAVITY SURGE",detail="Extra-low gravity for everyone"},
  {id="glowBall",name="LIGHTS OUT",detail="Follow the glowing ball"},
  {id="pickles",name="PICKLE STORM",detail="Watch your step on both sides"},
 }
 local index=self.random:NextInteger(1,self.chaosEvent and #events-1 or #events)
 if self.chaosEvent and index>=self.chaosEvent.index then index+=1 end
 local event=events[index]
 local endsAt=now+8
 for _,entry in ipairs(participants) do
  local effects=self:data(entry.player).effects
  if event.id=="speedCleats" or event.id=="bigPaddle" then effects[event.id]=math.max(effects[event.id] or 0,endsAt) end
 end
 if event.id=="zeroG" then self.zeroUntil=math.max(self.zeroUntil,endsAt)
 elseif event.id=="glowBall" then self.glowUntil=math.max(self.glowUntil,endsAt)
 elseif event.id=="pickles" then
  for _,side in ipairs({-1,1}) do
   for i=1,3 do
    local position=Vector3.new(self.random:NextNumber(-16,16),181.4,side*self.random:NextNumber(16,36))
    local part=Instance.new("Part"); part.Name="ChaosPickle"; part.Anchored=true; part.CanCollide=false; part.CanTouch=false
    part.Material=Enum.Material.Neon; part.Color=Color3.fromRGB(149,255,63)
    part.Size=Vector3.new(1.5,0.5,3); part.Position=position; part.Rotation=Vector3.new(0,self.random:NextNumber(-90,90),0); part.Parent=world
    table.insert(self.hazards,{part=part,position=position,side=side,expires=endsAt,kind="dropPickles",touched={}})
   end
  end
 end
 self.chaosEvent={index=index,name=event.name,detail=event.detail,endsAt=endsAt}
 self.chaosElapsed=0; self.chaosNext=self.random:NextInteger(10,14)
 return self.chaosEvent
end
function Arcade:pause(dt)
 self.zeroUntil+=dt; self.glowUntil+=dt
 if self.chaosEvent then self.chaosEvent.endsAt+=dt end
 for _,data in pairs(self.players) do
  if data.chaosHeatReadyAt then data.chaosHeatReadyAt+=dt end
  for id,value in pairs(data.effects) do if type(value)=="number" and value>0 then data.effects[id]+=dt end end
  for _,slot in pairs(data.slots) do if slot.readyAt then slot.readyAt+=dt; slot.activeUntil+=dt end end
 end
 for _,hazard in ipairs(self.hazards) do hazard.expires+=dt end
end
function Arcade:snapshot(player,now)
 self:empty(player,now)
 local slots={}
 for index=1,2 do
  local slot=self:data(player).slots[index]
  slots[index]=slot and {id=slot.id,charges=slot.charges or 0,armed=slot.armed==true,active=math.max(0,(slot.activeUntil or 0)-now),cooldown=math.max(0,(slot.readyAt or 0)-now),cooldownDuration=slot.cooldownDuration or Deck.COOLDOWN,duration=slot.duration or 0} or {id=""}
 end
 local event=self.chaosEvent
 local data=self:data(player)
 local values=Deck.chaosValues(data.levels)
 return {slots=slots,queued=#data.pending,levels=table.clone(data.levels),
  glow=now<self.glowUntil or (data.levels.glowBall or 0)>0,lightRange=values.lightRange,lightBrightness=values.lightBrightness,zeroG=self:gravity(now)<1,
  chaos=event and {name=event.name,detail=event.detail,remaining=math.max(0,event.endsAt-now)} or nil}
end
return Arcade
