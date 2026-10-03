-- Test the actual runtime's slam gate and body-save launch in detached fixtures.
return function(source,Rules,BodyBounce)
 local function section(first,last)
  local start=assert(source:find(first,1,true))
  local finish=assert(source:find(last,start+#first,true))
  return source:sub(start,finish-1)
 end
 local code=section("local function setMissImmune(","local function rosterChanged(")
  ..section("local function launch(","local function point(")
  .."\nreturn bodyReturn"
 for _,offset in ipairs({Vector3.zero,Vector3.new(5200,0,330)}) do
  for _,botContact in ipairs({false,true}) do
  local character=Instance.new("Model")
  local body=Instance.new("Part"); body.Name="Torso"; body.Size=Vector3.new(2,4,2)
  body.CFrame=CFrame.new(Vector3.new(0,184,-20)+offset); body.Parent=character
  local player={UserId=42,Character=character}
  local data={side=botContact and 1 or -1,perfectStreak=5}
  local ball={p=Vector3.new(0,184,-22),v=Vector3.new(0,-20,-56),last=1,
   speed=2,shots=3,bounces=0,live=true,slam=false,shotId=10}
  local contacts=0
  local environment=setmetatable({
   users={[player]=data},ball=ball,Rules=Rules,BodyBounce=BodyBounce,offset=offset,bot=character,
   FLOOR=181.7,GRAVITY=45,BASE_SPEED=56,lastHitter={},
   rootOf=function() return nil,{Health=100} end,
   lobCrossesSlamZone=function() return true end,
   crowd={shot=function() return false end,streakEnded=function() return false end},
   feedback={FireAllClients=function(_,_,kind) if kind=="ballHit" then contacts+=1 end end},
   tell=function() end,
  },{__index=getfenv()})
  local ok,result=pcall(function()
   local loader=assert(loadstring(code)); setfenv(loader,environment)
   local bodyReturn=loader()
   local previous=Vector3.new(0,184,-10)
   bodyReturn(previous,botContact)
   assert(contacts==0,"Ordinary shots must pass through bodies")
   ball.slam=true; ball.bounces=1
   bodyReturn(previous,botContact)
   assert(contacts==0,"Slams after a bounce must pass through bodies")
   ball.bounces=0
   bodyReturn(previous,botContact)
   assert(contacts==1 and ball.live and ball.lob,"Unbounced slams must become playable lobs")
   assert(ball.last==-1 and ball.shots==4 and ball.shotId==11,"Body saves must count as the receiver's return")
   assert(math.abs(ball.speed-1.4)<1e-8,"Body saves must reduce rally speed by 30 percent")
   assert(ball.v.Z>0 and Vector3.new(ball.v.X,0,ball.v.Z).Magnitude<=56*0.7+1e-8,"Body saves must travel slowly into the opposite court")
   assert(not ball.slam and not ball.bodyHitSide,"Body saves must allow paddle returns without another body save")
   if not botContact then
    assert(data.perfectStreak==0 and not data.missImmune,"Body contact must reset the receiver's streak and immunity")
    assert(environment.lastHitter[-1]==player,"Scoring must credit the body-saving player")
   else
    assert(data.perfectStreak==5,"Bot body saves must preserve the human opponent's streak")
    assert(environment.lastHitter[-1]==nil,"Bot body saves must not credit a human")
   end
   bodyReturn(previous,botContact)
   assert(contacts==1,"The resulting lob must not trigger another body contact")
  end)
  character:Destroy()
  assert(ok,result)
  end
 end
 return "Human/bot slam gate, playable slow lobs, streak reset and court-offset checks passed"
end
