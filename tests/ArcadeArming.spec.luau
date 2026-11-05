return function(Arcade,source)
 local engine=Arcade.new(Random.new(39)); engine:reset()
 local p,enemy={},{}
 local root={Position=Vector3.new(0,184,46)}
 local offer={{id="speedCleats"},{id="bigPaddle"}}
 engine:choose(p,offer,"speedCleats",0,true)
 engine:choose(p,offer,"bigPaddle",0,true)
 assert(engine:arm(p,1,0)==true)
 local slot=engine:snapshot(p,10).slots[1]
 assert(slot.armed and slot.active==0 and slot.cooldown==0 and slot.charges==1,"Arming spends no charges or effect time before serve")
 assert(not engine:effect(p,"speedCleats",10),"Armed effects wait for the actual serve")
 assert(engine:arm(p,1,10)==false,"Pressing again cancels the armed power")
 assert(not engine:snapshot(p,10).slots[1].armed)
 for _,bad in ipairs({0,3,1.5,"1"}) do assert(engine:arm(p,bad,10)==nil) end
 engine:arm(p,1,10); engine:arm(p,2,10)
 local first=assert(source:find("local function launch(",1,true))
 local last=assert(source:find("local function point(",first,true))
 local chunk=assert(loadstring(source:sub(first,last-1).."\nreturn launch"))
 local ball={live=false,speed=1}
 local activations=0
 local env=setmetatable({HEIGHT=0,ball=ball,GRAVITY=45,FLOOR=181.7,BASE_SPEED=56,arcade=engine,Rules={},
  os={clock=function() return 20 end},feedback={FireAllClients=function() end},
  activateArmedPowers=function(now)
   activations+=1
   assert(#engine:activateArmed(p,now,1,{enemy},root,nil,true)==2,"Both armed slots activate at the serve")
  end,
 },{__index=getfenv()})
 setfenv(chunk,env)
 local launch=chunk()
 launch(Vector3.new(0,184,46),Vector3.new(0,181.7,-28),false,false,false,0)
 assert(activations==1 and engine:effect(p,"speedCleats",20) and engine:effect(p,"bigPaddle",20))
 local snapshot=engine:snapshot(p,20)
 assert(not snapshot.slots[1].armed and snapshot.slots[1].charges==0 and snapshot.slots[1].active==8)
 assert(engine:arm(p,1,21)==nil,"Active/cooling slots cannot be armed")
 launch(Vector3.new(0,188,-20),Vector3.new(0,181.7,28),false,false,false,0)
 assert(activations==1,"Ordinary returns never retrigger armed powers")
 assert(#engine:activateArmed(p,21,1,{enemy},root,nil,true)==0,"Armed activation is consumed once")
 engine:reset()
 engine:choose(p,offer,"speedCleats",0,true); engine:arm(p,1,0)
 engine:choose(enemy,offer,"bigPaddle",0,true); engine:arm(enemy,1,0)
 engine:clearArmed(p)
 assert(not engine:snapshot(p,0).slots[1].armed and engine:snapshot(enemy,0).slots[1].armed,"Leaving clears only that player's armed powers")
 engine:clearArmed()
 assert(not engine:snapshot(enemy,0).slots[1].armed,"Rally faults clear stale armed powers")
 engine:reset()
 return "Pre-serve arming, cancel, validation, delayed charge/timers, actual serve activation, no retrigger on returns and cleanup passed"
end
