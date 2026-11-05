return function(Arcade)
 local a=Arcade.new(Random.new(123)); a:reset()
 local p,enemy={},{}
 local deck={"speedCleats","bigPaddle","heatseeker"}
 assert(not a:offer(p,{"speedCleats"},0),"Invalid decks are rejected")
 local offer=a:offer(p,deck,0); assert(#offer==3)
 assert(not a:choose(p,offer,"zeroG",0),"Cannot select a card outside the offer")
 local card,slot=a:choose(p,offer,"speedCleats",0); assert(card.id=="speedCleats" and slot==1)
 local root={Position=Vector3.new(0,184,28)}
 assert(not a:activate(p,3,1,1,{enemy},root,nil))
 assert(a:activate(p,1,1,1,{enemy},root,nil).id=="speedCleats")
 assert(not a:activate(p,1,2,1,{enemy},root,nil),"Active/cooling cards cannot be activated twice")
 assert(a:effect(p,"speedCleats",8) and not a:effect(p,"speedCleats",9))
 assert(a:choose(p,offer,"bigPaddle",1))
 assert(not a:offer(p,deck,2),"A full pair of slots gets no new offer")
 assert(a:activate(p,2,2,1,{enemy},root,nil))
 assert(a:reach(p,3)==1.75 and a:reach(p,12)==1)
 local snapshot=a:snapshot(p,3); assert(snapshot.slots[1].active==6 and snapshot.slots[2].active==9)
 a:pause(10); assert(a:effect(p,"bigPaddle",21) and not a:effect(p,"bigPaddle",22))
 assert(a:empty(p,37)==1,"Consumed cards free their slots after cooldown")
 a:choose(p,offer,"heatseeker",37); a:activate(p,1,38,1,{enemy},root,nil)
 local target=a:heatTarget(p,39,{Vector3.new(-15,184,-30)},1)
 assert(target.X==17 and target.Z==-35,"Heatseeker chooses the deepest open corner")
 assert(not a:heatTarget(p,39,{},1),"Heatseeker consumes only one hit")
 a:reset()
 local all={{id="smallPaddle"},{id="zeroG"},{id="glowBall"}}
 a:choose(p,all,"smallPaddle",0); a:activate(p,1,0,1,{enemy},root,nil)
 assert(a:reach(enemy,1)==0.5 and a:reach(p,1)==1)
 a:choose(p,all,"zeroG",0); a:activate(p,2,0,1,{enemy},root,nil)
 assert(a:gravity(1)==0.4 and a:gravity(8)==1)
 a:reset(); a:choose(p,all,"glowBall",0); a:activate(p,1,0,1,{enemy},root,nil)
 assert(a:snapshot(p,1).glow and not a:snapshot(p,8).glow)
 local world=Instance.new("Folder")
 local ok,err=pcall(function()
  for _,id in ipairs({"dropPickles","slipStream"}) do
   a:reset(); a:choose(p,{{id=id}},id,0); a:activate(p,1,0,1,{enemy},root,world)
   assert(#a.hazards==(id=="dropPickles" and 3 or 1))
   local position=a.hazards[1].position
   assert(not a:touch(p,1,position,1),"Hazards ignore their own team")
   assert(a:touch(enemy,-1,position,1),"Opponent contact triggers a slide")
   assert(not a:touch(enemy,-1,position,2.01),"A hazard cannot stun-lock a player")
   a:update(8); assert(#a.hazards==0 and #world:GetChildren()==0,"Hazards expire and clean up")
  end
 end)
 a:reset(); world:Destroy(); assert(ok,err)
 a:reset(); local count=0
 for i=1,20 do if a:rally() then assert(i-count>=2 and i-count<=4);count=i end end
 a:reset(); assert(next(a.players)==nil and #a.hazards==0)
 local valid={speedCleats=true,bigPaddle=true,dropPickles=true,heatseeker=true,slipStream=true,smallPaddle=true,glowBall=true,zeroG=true}
 for _=1,40 do
  local seen={}
  for _,card in ipairs(a:chaosOffer()) do
   assert(valid[card.id] and not seen[card.id],"Chaos only offers the shared eight powers, without duplicates")
   seen[card.id]=true; assert(card.art and card.blurb and not card.tier)
  end
 end
 local offer={{id="dropPickles"},{id="bigPaddle"},{id="speedCleats"}}
 assert(a:choose(p,offer,"dropPickles",0,true))
 assert(a:choose(p,offer,"dropPickles",0,true))
 assert(a:snapshot(p,0).slots[1].charges==2,"Chaos stacks copies of the same real power")
 a:choose(p,offer,"bigPaddle",0,true)
 a:choose(p,offer,"speedCleats",0,true)
 assert(a:snapshot(p,0).queued==1,"Full slots retain later Chaos picks")
 assert(not a:choose(p,{{id="erne"}},"erne",0,true),"Invented augment IDs cannot be acquired")
 a:activate(p,2,0,1,{enemy},root,nil)
 assert(a:snapshot(p,28).slots[2].id=="speedCleats","Queued powers move into consumed slots")
 local elevated=Arcade.new(Random.new(91),4096); elevated:reset()
 local world=Instance.new("Folder")
 elevated:choose(p,{{id="dropPickles"}},"dropPickles",0)
 elevated:activate(p,1,0,1,{enemy},{Position=Vector3.new(0,4280,28)},world)
 assert(#elevated.hazards==3 and math.abs(elevated.hazards[1].position.Y-(181.4+4096))<0.001,"Hazards belong to the elevated court")
 elevated:choose(p,{{id="heatseeker"}},"heatseeker",0)
 elevated:activate(p,2,0,1,{enemy},root,world)
 assert(math.abs(elevated:heatTarget(p,0,{Vector3.new(0,4280,-28)},1).Y-(181.7+4096))<0.001,"Homing targets use the same court height")
 assert(#a.hazards==0,"Elevated court powers cannot spawn hazards in another runtime")
 elevated:reset(); world:Destroy()
 a:reset()
end
