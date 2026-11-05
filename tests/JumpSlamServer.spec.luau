-- Run the actual return and launch code with isolated player/ball state.
return function(source,Rules,Powerups,Comeback)
 local launchFirst=assert(source:find("local function launch(",1,true))
 local launchLast=assert(source:find("local function point(",launchFirst,true))
 local returnFirst=assert(source:find("local function overheadStatus(",1,true))
 local returnLast=assert(source:find("connect(input.OnServerEvent,",returnFirst,true))
 local ball={}
 local faults,events={},{}
 local character={Humanoid={FloorMaterial=Enum.Material.Air,Health=100}}
 function character:FindFirstChild() return nil end
 function character:FindFirstChildOfClass() return self.Humanoid end
 function character:SetAttribute() end
 local player={UserId=42,Character=character}
 local root={Position=Vector3.new(0,188,16),AssemblyLinearVelocity=Vector3.zero}
 local data={}
 local env=setmetatable({HEIGHT=0,
  Rules=Rules,Powerups=Powerups,Comeback=Comeback,comeback=Comeback.new(),
  ball=ball,GRAVITY=45,FLOOR=181.7,BASE_SPEED=56,servingSide=1,lastHitter={},users={},
  feedback={FireAllClients=function(_,event,kind) table.insert(events,{event=event,kind=kind}) end},
  perfect=function() return false end,landing=function() return Vector3.zero,1 end,
  facingTarget=function(_,_,side) return Vector3.new(0,181.7,-side*35),0 end,
  rootOf=function() return root,character.Humanoid end,
  point=function(_,reason) table.insert(faults,reason) end,
  teamPlayers=function() return {} end,activatePowerup=function() end,tell=function() end,
  lobCrossesSlamZone=function() return false end,
 },{__index=getfenv()})
 local chunk=assert(loadstring(source:sub(launchFirst,launchLast-1)..source:sub(returnFirst,returnLast-1).."\nreturn tryReturn,slamReady"))
 setfenv(chunk,env)
 local tryReturn,slamReady=chunk()
 for _,side in ipairs({-1,1}) do
  for _,case in ipairs({{0.1,"net"},{0,"perfect"},{-0.1,"out"}}) do
   table.clear(events); table.clear(faults); table.clear(ball); table.clear(data)
   root.Position=Vector3.new(0,188,side*16)
   root.CFrame=CFrame.lookAt(root.Position,Vector3.new(0,188,0))
   local contact=root.Position+root.CFrame.LookVector*5+Vector3.new(0,1.5,0)
   ball.v=Vector3.new(0,-12,side*40); ball.p=contact-ball.v*case[1]
   ball.live=true; ball.last=-side; ball.shots=2; ball.bounces=0; ball.bounceAt=-100
   ball.speed=1; ball.perfects=0
   data.side=side; data.powerups={}; data.powerupMatch={}; data.powerupRally=Powerups.newRally()
   data.diveUntil=0; data.divePoseUntil=0; data.lastSwing=0; data.powerUntil=0
   assert(slamReady(player,data,10)==(case[2]=="perfect"),"Slam readiness must match actual timing")
   assert(tryReturn(player,data,root,10,false,false,0),"In-range airborne swing must connect")
   assert(#faults==0 and ball.slam and not ball.lob,"Every timing grade keeps the slam trajectory")
   local crossing=-ball.p.Z/ball.v.Z
   local net=Rules.advanceBall(ball.p,ball.v,ball.flightGravity,crossing,false,false)
   if case[2]=="net" then
    assert(net.Y<184.65 and net.Y>181.7,"Early slam physically strikes net")
   else
    assert(net.Y>=185.2-1e-6,"Perfect and late slams clear the net")
    local duration=Rules.ballLandingTime(ball.p.Y-181.7,ball.v.Y,ball.flightGravity,false,false)
    local landing=Rules.advanceBall(ball.p,ball.v,ball.flightGravity,duration,false,false)
    assert((math.abs(landing.Z)>Rules.BASELINE)==(case[2]=="out"),"Late lands out; perfect lands in")
   end
   assert(ball.perfects==(case[2]=="perfect" and 1 or 0),"Mistimed slams must not earn perfect credit")
   local message=events[#events].event
   if case[2]=="net" then assert(message.text=="EARLY SLAM / NET" and message.tone=="bad")
   elseif case[2]=="out" then assert(message.text=="LATE SLAM / OUT" and message.tone=="bad") end
  end
 end
 return "Actual server jump slams: early net collision, perfect in-bounds landing, late out landing, timing UI and credit passed on both sides"
end
