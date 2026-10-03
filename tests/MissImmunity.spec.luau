-- Exercise the actual server functions in an isolated environment.
return function(source,Rules)
 local function section(first,last)
  local start=assert(source:find(first,1,true))
  local finish=assert(source:find(last,start+#first,true))
  return source:sub(start,finish-1)
 end
 local code=section("local function setMissImmune(","local function rosterChanged(")
  ..section("local function launch(","local function bodyReturn(")
  ..section("local function tryReturn(","local function handleInput(")
  .."\nreturn {launch=launch,tryReturn=tryReturn,setStreak=setStreak}"
 for _,side in ipairs({-1,1}) do
  local attributes={PerfectStreak=3,HitReadyAt=0}
  local player={UserId=42,Character={SetAttribute=function(_,key,value) attributes[key]=value end}}
  local data={side=side,perfectStreak=3,lastSwing=0}
  local ball={last=side,speed=1,shots=3}
  local misses,events,reachChecks=0,0,0
  local environment=setmetatable({
   users={[player]=data},ball=ball,Rules=Rules,FLOOR=181.7,GRAVITY=45,BASE_SPEED=56,offset=Vector3.zero,
   crowd={shot=function() return false end,streakEnded=function() return false end},
   feedback={FireAllClients=function() events+=1 end},
   workspace={GetServerTimeNow=function() return 10 end},
   overheadStatus=function() reachChecks+=1; return 100,false end,
   tell=function(_,_,kind) if kind=="miss" then misses+=1 end end,
  },{__index=getfenv()})
  local loader=assert(loadstring(code)); setfenv(loader,environment)
  local server=loader()
  local function launch(last,contact)
   ball.last=last
   server.launch(Vector3.new(0,185,20),Vector3.new(0,181.7,30),false,false,false,0,nil,false,0,contact)
  end
  local root={CFrame=CFrame.new(),Position=Vector3.zero}
  launch(side,{userId=42,clean=true})
  assert(data.missImmune and attributes.MissImmune,"Perfect hit must grant replicated immunity")
  local priorEvents=events
  for _,automatic in ipairs({false,true}) do
   for _,soft in ipairs({false,true}) do
    server.tryReturn(player,data,root,10,automatic,soft,1)
   end
  end
  ball.bounces=1
  server.tryReturn(player,data,root,10,false)
  assert(data.perfectStreak==3 and misses==0 and events==priorEvents,"Follow-up inputs and bounces must preserve the streak without feedback")
  assert(data.lastSwing==0 and attributes.HitReadyAt==0 and reachChecks==0,"Immune swings must not apply a cooldown or evaluate contact")
  launch(-side,{userId=43,clean=false})
  assert(not data.missImmune and not attributes.MissImmune,"Opponent return must end immunity even when not perfect")
  server.tryReturn(player,data,root,10,false)
  assert(misses==1 and data.perfectStreak==0,"A miss after the opponent returns must count normally")
  launch(side,{userId=42,clean=true})
  server.setStreak(player,data,0)
  assert(not data.missImmune and not attributes.MissImmune,"Point, lobby and respawn resets must clear immunity")
  launch(side,{userId=42,clean=false})
  assert(not data.missImmune,"Ordinary hits must not grant immunity")
 end
 return "Perfect-hit immunity, repeated inputs, bounces, opponent returns, cooldown preservation and resets passed for both teams"
end
