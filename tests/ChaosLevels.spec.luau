return function(Arcade,Deck)
 local engine=Arcade.new(Random.new(273)); engine:reset()
 local a,b={},{}
 local participants={{player=a,side=1},{player=b,side=-1}}
 local world=Instance.new("Folder")
 local function grant(id,level)
  for _=1,level do
   local previous=engine:data(a).levels[id] or 0
   local card=Deck.chaosCard(id,previous)
   assert(engine:chooseChaos(a,{card},id))
  end
 end
 local ok,result=pcall(function()
  for _,base in ipairs(Deck.cards) do
   local before=Deck.chaosCard(base.id,0)
   assert(before.art==base.art and before.levelLabel=="NEW  /  LEVEL 1")
   local first,last=Deck.chaosValues({[base.id]=1}),Deck.chaosValues({[base.id]=5})
   assert(before.description~=Deck.chaosCard(base.id,4).description,"Every power's upgrade copy changes with its strength")
   grant(base.id,5)
   assert(engine:data(a).levels[base.id]==5)
   assert(not engine:chooseChaos(a,{Deck.chaosCard(base.id,5)},base.id),"Maximum level cannot overflow")
  end
  assert(not engine:chaosUpgradeOffer(a),"Fully maxed builds receive no empty choices")
  assert(not engine:chooseChaos(a,{{id="afterimage",chaosUpgrade=true,previousLevel=0}},"afterimage"),"Only the original eight powers are valid")
  assert(engine:speed(a,0)==1.75 and engine:swingScale(a,0)==0.8)
  engine:chaosUpdate(0,0,participants,world,false)
  assert(engine:reach(a,0)==2 and math.abs(engine:reach(b,0)-0.7)<1e-6,"Large paddles and opponent shrink use their levels")
  assert(math.abs(engine:gravity(0)-0.6)<1e-6,"Permanent Zero-G uses the strongest build")
  local snapshot=engine:snapshot(a,0)
  assert(snapshot.glow and snapshot.lightRange==39 and snapshot.lightBrightness==8 and snapshot.levels.glowBall==5)
  local target=engine:heatTarget(a,0,{Vector3.new(-15,184,-30)},1)
  assert(target and target.X==17 and not engine:heatTarget(a,1,{},1))
  assert(engine:heatTarget(a,6.5,{},1),"High-level Heatseeker recharges sooner")
  engine:pause(10)
  assert(not engine:heatTarget(a,22.9,{},1) and engine:heatTarget(a,23,{},1),"Practice pause preserves Heatseeker recharge")
  engine:chaosUpdate(6.5,20,participants,world,true)
  assert(#engine.hazards==4,"Level five creates three pickles and one slick zone")
  for _,hazard in ipairs(engine.hazards) do
   assert(hazard.side==-1,"Automatic hazards target the opponent's side")
   if hazard.kind=="slipStream" then
    assert(hazard.part.Size.X==16,"Slip Stream grows with levels")
    assert(engine:touch({},-1,hazard.position+Vector3.new(7,0,7),20),"Larger slick area actually trips opponents at its edges")
   end
  end
  engine:update(27)
  assert(#engine.hazards==0,"Automatic hazards expire")
  engine:chaosUpdate(100,30,participants,world,false)
  assert(#engine.hazards==0,"Serve countdowns do not spawn hazards")
  local levels=engine:snapshot(a,100).levels
  assert(levels.speedCleats==5 and levels.bigPaddle==5,"Levels never expire between rallies")
  engine:reset(); engine:chaosUpdate(0,100,participants,world,false)
  assert(engine:speed(a,100)==1 and engine:reach(b,100)==1 and engine:gravity(100)==1)
  local offer=engine:chaosUpgradeOffer(a)
  assert(#offer==3 and offer[1].id~=offer[2].id and offer[2].id~=offer[3].id)
  return "Original eight powers level to five; passive strength, homing recharge, auto-hazards, light/gravity, persistence, cap, pause and reset passed"
 end)
 engine:reset(); world:Destroy(); assert(ok,result); return result
end
