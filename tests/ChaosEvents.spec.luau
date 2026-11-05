return function(Arcade,Deck)
 local engine=Arcade.new(Random.new(881)); engine:reset()
 local a,b={},{}
 local participants={{player=a,side=1},{player=b,side=-1}}
 local world=Instance.new("Folder")
 local ok,result=pcall(function()
  assert(not engine:chaosStep(3,3,participants,world),"Events wait for live play")
  local first=assert(engine:chaosStep(1,4,participants,world))
  assert(engine:snapshot(a,4).chaos.name==first.name,"All clients receive the shared event")
  local previous=first.index
  local seen={[first.name]=true}
  local now=20
  for _=1,80 do
   engine:update(now)
   local event=assert(engine:chaosStep(14,now,participants,world))
   assert(event.index~=previous,"Events never repeat back to back")
   previous=event.index; seen[event.name]=true
   assert(engine:snapshot(a,now).chaos.remaining==8)
   if event.name=="SPEED FRENZY" then
    assert(engine:effect(a,"speedCleats",now) and engine:effect(b,"speedCleats",now),"Speed applies to both teams")
   elseif event.name=="GIANT PADDLES" then
    assert(engine:reach(a,now)==1.75 and engine:reach(b,now)==1.75)
   elseif event.name=="GRAVITY SURGE" then
    assert(engine:gravity(now)==0.4 and engine:gravity(now+8)==1)
   elseif event.name=="LIGHTS OUT" then
    assert(engine:snapshot(a,now).glow and not engine:snapshot(a,now+8).glow)
   else
    assert(#engine.hazards==6,"Pickle storm creates three hazards on each side")
    local sides={[-1]=0,[1]=0}
    for _,hazard in ipairs(engine.hazards) do
     sides[hazard.side]+=1
     assert(math.abs(hazard.position.X)<=16 and math.abs(hazard.position.Z)>=16 and math.abs(hazard.position.Z)<=36)
    end
    assert(sides[-1]==3 and sides[1]==3)
   end
   engine:update(now+9)
   assert(#engine.hazards==0,"Storm hazards clean up after eight seconds")
   now+=20
  end
  local count=0; for _ in pairs(seen) do count+=1 end
  assert(count==5,"All five Chaos events occur")
  engine:reset()
  for _=1,12 do assert(engine:chaosGift(a,0),"Every rally adds a real power even with full slots") end
  local snapshot=engine:snapshot(a,0)
  assert(snapshot.queued>0 or snapshot.slots[1].charges>1 or snapshot.slots[2].charges>1,"Rewards stack or queue")
  engine:reset()
  engine:choose(a,{{id="heatseeker"}},"heatseeker",0,true)
  engine:activate(a,1,0,1,{b},{Position=Vector3.new(0,184,28)},world,true)
  engine:heatTarget(a,1,{},1)
  assert(engine:snapshot(a,1).slots[1].cooldown==Deck.CHAOS_COOLDOWN,"Chaos powers have a five-second cooldown")
  engine:pause(10)
  assert(engine:snapshot(a,11).slots[1].cooldown==Deck.CHAOS_COOLDOWN,"Practice pause preserves cooldown")
  engine:reset()
  assert(not engine:snapshot(a,0).chaos and #world:GetChildren()==0,"Leaving/reset clears events and hazards")
  return "Five Chaos events, both-team effects, no consecutive repeats, hazard bounds/cleanup, stacking rewards, cooldowns and pause passed"
 end)
 engine:reset(); world:Destroy(); assert(ok,result); return result
end
