-- Server-authoritative arcade pickleball.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
game:GetService("StarterPlayer").EnableMouseLockOption=false
require(script:WaitForChild("World")).build()
local folder=ReplicatedStorage:FindFirstChild("PaddleUp") or Instance.new("Folder")
folder.Name="PaddleUp"; folder.Parent=ReplicatedStorage
local function remote(name)
 local r=folder:FindFirstChild(name) or Instance.new("RemoteEvent")
 r.Name=name; r.Parent=folder
 return r
end
local input,state,feedback=remote("Input"),remote("State"),remote("Feedback")
local FLOOR,GRAVITY,BASE_SPEED=181.7,45,56
local Rules=require(script:WaitForChild("MatchRules"))
local users={}
local score={0,0}
local ball={p=Vector3.new(0,187,-28),v=Vector3.zero,g=GRAVITY,live=false,last=-1,bounces=0,perfects=0,speed=1,bounceAt=-100}
local nextServe=0
local servingSide,serveReady,serveX=1,false,10
local serverId,receiverId
ball.shots=0
local banner="Welcome to Skyline Club"
local botSlowUntil=0
local botX,botZ=0,-28
local world=workspace:WaitForChild("PaddleUp")
local bot=Instance.new("Model")
bot.Name="Practice Partner"; bot.Parent=world
local function botPart(name,size,color)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.Color=color; p.Anchored=true; p.CanCollide=false; p.Parent=bot
 return p
end
local botBody=botPart("Body",Vector3.new(2.4,2.6,1.4),Color3.fromRGB(240,135,104))
local botHead=botPart("Head",Vector3.new(1.5,1.5,1.5),Color3.fromRGB(233,227,209)); botHead.Shape=Enum.PartType.Ball
local botPaddle=botPart("Paddle",Vector3.new(1.5,2.2,0.3),Color3.fromRGB(35,193,182))
local botLegs={botPart("Left leg",Vector3.new(0.8,2,0.8),Color3.fromRGB(35,55,63)),botPart("Right leg",Vector3.new(0.8,2,0.8),Color3.fromRGB(35,55,63))}
local tag=Instance.new("BillboardGui",botHead); tag.Size=UDim2.fromOffset(180,35); tag.StudsOffset=Vector3.new(0,2,0); tag.AlwaysOnTop=true
local tagText=Instance.new("TextLabel",tag); tagText.Size=UDim2.fromScale(1,1); tagText.BackgroundTransparency=1; tagText.Text="PRACTICE PARTNER"; tagText.TextColor3=Color3.fromRGB(249,235,204); tagText.Font=Enum.Font.GothamBold; tagText.TextSize=12
local function teamPlayers(side)
 local team={}
 for p,d in pairs(users) do if d.side==side then table.insert(team,p) end end
 table.sort(team,function(a,b) return users[a].slot<users[b].slot end)
 return team
end
local function occupant(side)
 local p=teamPlayers(side)[1]
 if p then return p,users[p] end
end
local function availableSlot(side)
 local occupied={}
 for _,d in pairs(users) do if d.side==side then occupied[d.slot]=true end end
 for slot=1,2 do if not occupied[slot] then return slot end end
end
local function rootOf(p)
 local c=p.Character
 return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end
local function tell(p,text,kind)
 feedback:FireClient(p,text,kind or "info")
end
local function landing()
 if not ball.live then return ball.p,0 end
 local h=math.max(0,ball.p.Y-FLOOR)
 local t=(ball.v.Y+math.sqrt(ball.v.Y*ball.v.Y+2*ball.g*h))/ball.g
 return ball.p+Vector3.new(ball.v.X*t,-h,ball.v.Z*t),t
end
local function perfect(now)
 local _,t=landing()
 return t<=0.23 or now-ball.bounceAt<=0.28
end
local function launch(from,target,boost,lob,slam)
 local speedScale=ball.speed*(boost and 1.22 or 1)
 -- Solve a clear arc at base speed, then scale time and gravity together.
 -- Speed scaling preserves the solved trajectory for perfects, slams, and lobs.
 local distance=(Vector3.new(target.X,0,target.Z)-Vector3.new(from.X,0,from.Z)).Magnitude
 local gravity=slam and GRAVITY*1.8 or GRAVITY
 local duration=slam and math.max(0.12,math.min(distance/(BASE_SPEED*1.8),math.sqrt(2*math.max(0.1,from.Y-FLOOR)/gravity)*0.75)) or math.max(0.7,distance/BASE_SPEED)
 local vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
 local crossing=(0-from.Z)/(target.Z-from.Z)
 if crossing>0 and crossing<1 then
  local tc=duration*crossing
  local netY=from.Y+vy*tc-0.5*gravity*tc*tc
  if netY<185.2 then
   duration=math.sqrt(math.max(0.01,2*(185.2-from.Y-(FLOOR-from.Y)*crossing)/(gravity*crossing*(1-crossing))))
   vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
  end
 end
 if lob then
  -- A higher arc buys recovery time while preserving the landing target.
  duration=math.max(duration*1.35,1.5)
  vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
 end
 ball.p=from
 ball.g=gravity*speedScale*speedScale
 ball.v=Vector3.new((target.X-from.X)/duration,vy,(target.Z-from.Z)/duration)*speedScale
 ball.bounces=0; ball.bounceAt=-100; ball.live=true
 feedback:FireAllClients(from,"ballHit")
end
local function point(winner,reason)
 if not ball.live then return end
 ball.live=false; ball.v=Vector3.zero; ball.perfects=0; ball.speed=1
 local index=winner==1 and 1 or 2
 score[index]+=1
 banner=(winner==1 and "HOME" or "AWAY").." POINT  /  "..reason
 servingSide=winner; serveReady=false
 for _,d in pairs(users) do d.diveUntil=0; d.volleyPending=false end
 nextServe=os.clock()+2.5
 feedback:FireAllClients(banner,"point")
 if score[index]>=11 and math.abs(score[1]-score[2])>=2 then
  banner=(winner==1 and "HOME" or "AWAY").." WINS!  /  New game in 6 seconds"
  feedback:FireAllClients(banner,"point")
  nextServe=os.clock()+6
  ball.resetScore=true; servingSide=1
 end
end
local function paddle(character)
 local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
 if not hand then return end
 local function attach(name,size,offset,color)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Color=color; p.Material=Enum.Material.SmoothPlastic
  p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
  p.CFrame=hand.CFrame*offset; p.Parent=character
  local weld=Instance.new("WeldConstraint",p); weld.Part0=hand; weld.Part1=p
  return p
 end
 attach("PaddleGrip",Vector3.new(0.3,1.2,0.3),CFrame.new(0,-0.7,0),Color3.fromRGB(35,47,52))
 local face=attach("PaddleFace",Vector3.new(1.65,2,0.3),CFrame.new(0,-2,0),Color3.fromRGB(31,193,180))
 face:SetAttribute("Paddle",true)
end
local function spawnCharacter(p,c)
 local d=users[p]; if not d then return end
 local r=c:WaitForChild("HumanoidRootPart",10)
 local h=c:WaitForChild("Humanoid",10)
 if not r or not h then return end
 h.WalkSpeed=18; h.UseJumpPower=true; h.JumpPower=38
 local z=d.side==0 and 58 or d.side*28
 c:PivotTo(CFrame.lookAt(Vector3.new(d.side==0 and 40 or 0,185,z),Vector3.new(0,185,0)))
 paddle(c)
 d.kitchenTouched=false; d.volleyPending=false; d.diveUntil=0
 if not ball.live then serveReady=false end
end
local function addPlayer(p)
 if users[p] then return end
 local home,away=#teamPlayers(1),#teamPlayers(-1)
 local side=home<2 and (home<=away or away>=2) and 1 or (away<2 and -1 or 0)
 users[p]={side=side,slot=side~=0 and availableSlot(side) or 0,stamina=100,lastSwing=0,diveAt=0,powerAt=0,slowAt=0,powerUntil=0,slowUntil=0,lastInput=0}
 p:SetAttribute("CourtSide",side)
 p.CharacterAdded:Connect(function(c) spawnCharacter(p,c) end)
 if p.Character then task.spawn(spawnCharacter,p,p.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
for _,p in ipairs(Players:GetPlayers()) do addPlayer(p) end
Players.PlayerRemoving:Connect(function(p)
 local leaving=users[p]
 users[p]=nil
 if leaving and leaving.side~=0 then
  ball.live=false; ball.v=Vector3.zero; serveReady=false; servingSide=1; nextServe=os.clock()+1
  for waiting,d in pairs(users) do
   if d.side==0 then d.slot=availableSlot(leaving.side); d.side=leaving.side; waiting:SetAttribute("CourtSide",d.side); if waiting.Character then task.spawn(spawnCharacter,waiting,waiting.Character) end; break end
  end
  if not occupant(1) then
   local remaining,d=occupant(-1)
   if remaining then
    d.slot=availableSlot(1); d.side=1; remaining:SetAttribute("CourtSide",1)
    if remaining.Character then task.spawn(spawnCharacter,remaining,remaining.Character) end
   end
  end
 end
end)
local function prepareServe()
 if ball.resetScore then score={0,0}; ball.resetScore=false end
 if not occupant(servingSide) and servingSide==1 then return end
 serveX=Rules.serveX(servingSide,score[servingSide==1 and 1 or 2])
 local server=occupant(servingSide)
 local receiver=occupant(-servingSide)
 serverId=server and server.UserId
 receiverId=receiver and receiver.UserId
 for p,d in pairs(users) do
  local r,h=rootOf(p)
  if d.side~=0 and r and h and h.Health>0 then
   local primary=p.UserId==(d.side==servingSide and serverId or receiverId)
   local position=Rules.startPosition(d.side,servingSide,serveX,primary)
   p.Character:PivotTo(CFrame.lookAt(position,Vector3.new(position.X,185,0)))
   r.AssemblyLinearVelocity=Vector3.zero
   d.diveUntil=0; d.volleyPending=false; d.kitchenTouched=false
  end
 end
 if servingSide==-1 and not occupant(-1) then botX=serveX; botZ=-46
 else botX=-serveX; botZ=-46 end
 ball.p=Vector3.new(serveX,184,servingSide*46)
 ball.v=Vector3.zero; ball.speed=1; ball.perfects=0; ball.shots=0
 ball.bounces=0; ball.bounceAt=-100; ball.last=servingSide
 serveReady=true
 banner=(servingSide==1 and "HOME" or "AWAY").." TO SERVE"
end
local function serve(p,d,r,h)
 if not serveReady then return end
 local botServing=servingSide==-1 and not occupant(-1)
 if p.UserId~=serverId and not (botServing and p.UserId==receiverId) then
  tell(p,"WAIT FOR THE DESIGNATED SERVER","info"); return
 end
 local from=Vector3.new(serveX,184,servingSide*46)
 if not botServing then
  if not Rules.servePositionValid(r.Position,d.side,serveX,h.FloorMaterial~=Enum.Material.Air) then
   tell(p,"SERVE FROM BEHIND THE BASELINE ON THE MARKED SIDE","miss"); return
  end
  from=Vector3.new(r.Position.X,184,r.Position.Z)
  feedback:FireAllClients({userId=p.UserId,backhand=false},"swing")
 end
 serveReady=false; ball.last=servingSide; ball.shots=0
 launch(from,Vector3.new(-serveX,FLOOR,-servingSide*28),false)
 banner="SERVE  /  LET IT BOUNCE"
end
local function tryReturn(p,d,r,now,moveAtImpact,automatic)
  if now<d.lastSwing then return false end
  local face=p.Character:FindFirstChild("PaddleFace")
  local center=face and face.Position or r.Position
  local distance=(ball.p-center).Magnitude
  local head=p.Character:FindFirstChild("Head")
  local headTop=head and head.Position.Y+head.Size.Y*0.5 or r.Position.Y+3
  local armLength=0
  for _,name in ipairs({"RightUpperArm","RightLowerArm","RightHand","Right Arm"}) do
   local part=p.Character:FindFirstChild(name)
   if part then armLength+=part.Size.Y end
  end
  armLength=math.clamp(armLength,2,6)
  local overhead=distance<=Rules.SLAM_RANGE and Rules.overheadReach(ball.p,r.Position,headTop,armLength)
  local inReach=distance<=Rules.HIT_RANGE or overhead
  local valid=ball.live and ball.last~=d.side and ball.p.Z*d.side>=-1 and inReach
  if automatic and not valid then return false end
  local clean=valid and (distance<=Rules.PERFECT_RANGE or overhead) and perfect(now)
  d.lastSwing=clean and now or now+0.28
  local backhand=r.CFrame:PointToObjectSpace(ball.p).X<0
  feedback:FireAllClients({userId=p.UserId,backhand=backhand},"swing")
  if not valid then tell(p,"MOVE INTO THE BALL","miss"); return end
  if ball.shots==0 and receiverId and p.UserId~=receiverId then
   point(-d.side,"Wrong receiver: the diagonal player must return the serve"); return false
  end
  local fault=Rules.returnFault(ball.bounces,ball.shots,d.kitchenTouched or Rules.inKitchen(r.Position,1))
  if fault then point(-d.side,fault); return false end
  if ball.bounces==0 then d.volleyPending=true; d.volleySettled=0 end
  ball.shots+=1
  local slam=clean and overhead
  local restored=clean and ball.speed<1
  if clean then ball.perfects+=1 end
  ball.speed=Rules.returnSpeed(ball.speed,clean,slam)
  local moving=Vector3.zero
  if typeof(moveAtImpact)=="Vector3" and moveAtImpact.X==moveAtImpact.X and moveAtImpact.Z==moveAtImpact.Z then
   local horizontal=Vector3.new(moveAtImpact.X,0,moveAtImpact.Z)
   if horizontal.Magnitude<=1.1 then moving=horizontal.Magnitude>1 and horizontal.Unit or horizontal end
  end
  -- World-space movement is inherited at impact; position also influences placement.
  local targetX=math.clamp(r.Position.X*0.3+moving.X*17,-18,18)
  local targetDepth=math.clamp(27-moving.Z*d.side*10,17,37)
  if slam then targetDepth=math.clamp(targetDepth,32,38) end
  local powered=clean and now<d.powerUntil
  d.powerUntil=0
  ball.last=d.side
  launch(ball.p,Vector3.new(targetX,FLOOR,-d.side*targetDepth),powered,not clean,slam)
  local message=restored and (slam and "SLAM!  SPEED RESET TO 1.00x" or "PERFECT!  SPEED RESET TO 1.00x")
   or (slam and "SLAM!  +10%" or (clean and "PERFECT!  +5%" or "LOB RETURN  /  -5%"))
  tell(p,message,slam and "slam" or (clean and "perfect" or "hit"))
  d.diveUntil=0
  return true
end
input.OnServerEvent:Connect(function(p,action,moveAtImpact)
 local d=users[p]
 if not d or d.side==0 or type(action)~="string" then return end
 local now=os.clock()
 -- Remote flood protection does not impose a gameplay cooldown on perfect returns.
 if now-d.lastInput<0.015 then return end
 d.lastInput=now
 local r,h=rootOf(p)
 if not r or not h or h.Health<=0 then return end
 if action=="Serve" or (action=="Swing" and not ball.live) then
  serve(p,d,r,h)
 elseif action=="Dive" then
  if now<d.diveAt or d.stamina<35 then return end
  d.stamina-=35; d.diveAt=now+1.6
  d.diveUntil=now+0.8; d.diveCharacter=p.Character
  local delta=ball.live and Vector3.new(ball.p.X-r.Position.X,0,ball.p.Z-r.Position.Z) or Vector3.zero
  local direction=delta.Magnitude>1 and delta.Unit or Vector3.new(r.CFrame.LookVector.X,0,r.CFrame.LookVector.Z)
  if direction.Magnitude<0.1 then direction=Vector3.new(0,0,-d.side) end
  feedback:FireAllClients({userId=p.UserId,direction=direction.Unit},"diveMotion")
  tell(p,"DIVE","dive")
 elseif action=="Power" then
  if now<d.powerAt then return end
  d.powerAt=now+10; d.powerUntil=now+5
  tell(p,"POWER SHOT ARMED  /  5s","power")
 elseif action=="Slow" then
  if now<d.slowAt then return end
  d.slowAt=now+12
  local opponents=teamPlayers(-d.side)
  if #opponents==0 then botSlowUntil=now+2.5 end
  for _,opponent in ipairs(opponents) do
   users[opponent].slowUntil=now+2.5; tell(opponent,"SLOWED  /  2.5s","slow")
  end
  tell(p,"OPPONENT SLOWED","power")
 elseif action=="Swing" then
  tryReturn(p,d,r,now,moveAtImpact,false)
 end
end)
local accumulator,broadcast=0,0
RunService.Heartbeat:Connect(function(dt)
 local now=os.clock()
 for p,d in pairs(users) do
  d.stamina=math.min(100,d.stamina+dt*22)
  local r,h=rootOf(p)
  if r and h and h.Health>0 then
   h.WalkSpeed=now<d.slowUntil and 10 or 18
   local grounded=h.FloorMaterial~=Enum.Material.Air
   local inKitchen=Rules.inKitchen(r.Position,1)
   if grounded then d.kitchenTouched=inKitchen end
   if d.volleyPending and ball.live then
    if inKitchen then
     point(-d.side,"Kitchen momentum fault")
    elseif grounded and Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude<2 then
     d.volleySettled=(d.volleySettled or 0)+dt
     if d.volleySettled>0.15 then d.volleyPending=false end
    else d.volleySettled=0 end
   end
   if d.side~=0 then
    local x=math.clamp(r.Position.X,-30,30)
    local z=d.side*math.clamp(r.Position.Z*d.side,2.5,Rules.BACK_LIMIT)
    if math.abs(x-r.Position.X)>0.1 or math.abs(z-r.Position.Z)>0.1 or r.Position.Y<178 then
     r.CFrame=CFrame.new(x,math.max(r.Position.Y,184),z)*r.CFrame.Rotation
    end
   end
  end
 end
 local hasBot=occupant(-1)==nil
 for _,p in ipairs(bot:GetChildren()) do if p:IsA("BasePart") then p.Transparency=hasBot and 0 or 1 end end
 tag.Enabled=hasBot
 if not ball.live and not serveReady and now>=nextServe and occupant(1) then prepareServe() end
 if ball.live then
  accumulator+=math.min(dt,0.1)
  while accumulator>=1/120 and ball.live do
   local step=1/120
   accumulator-=step
   -- Check throughout the dive at the same fixed rate as ball physics.
   for p,d in pairs(users) do
    if d.side~=0 and d.diveUntil and now<d.diveUntil and p.Character==d.diveCharacter then
     local r,h=rootOf(p)
     if r and h and h.Health>0 then tryReturn(p,d,r,now,h.MoveDirection,true) end
    end
   end
   if not ball.live then break end
   local previous=ball.p
   ball.p+=ball.v*step+Vector3.new(0,-0.5*ball.g*step*step,0)
   ball.v+=Vector3.new(0,-ball.g*step,0)
   if previous.Z*ball.p.Z<=0 and math.abs(ball.p.X)<21 and ball.p.Y<184.65 then
    point(-ball.last,"Net")
   elseif ball.p.Y<=FLOOR then
    if ball.bounces>=1 then
     point(ball.last,"Double bounce")
    elseif ball.shots==0 and not Rules.serveLandingValid(ball.p,servingSide,serveX) then
     point(-servingSide,"Serve fault: land in the diagonal service court")
    elseif math.abs(ball.p.X)>20.09 or math.abs(ball.p.Z)>40.09 then
     point(-ball.last,"Out")
    elseif ball.p.Z*ball.last>0 then
     point(-ball.last,"Short return")
    else
     ball.bounces+=1
     if ball.bounces>=2 then point(ball.last,"Double bounce")
     else
      ball.p=Vector3.new(ball.p.X,FLOOR,ball.p.Z)
      ball.v=Vector3.new(ball.v.X,math.max(15,-ball.v.Y*0.78),ball.v.Z)
      ball.bounceAt=now
      ball.bouncePoint=ball.p
     end
    end
   elseif math.abs(ball.p.Z)>65 or math.abs(ball.p.X)>45 then
    point(ball.bounces>0 and ball.last or -ball.last,"Rally over")
   end
  end
 else accumulator=0 end
 if hasBot and ball.live then
  local predicted=landing()
  local tx=ball.live and ball.last==1 and math.clamp(predicted.X,-18,18) or 0
  local tz=ball.live and ball.last==1 and math.clamp(predicted.Z,-37,-8) or -28
  local delta=Vector3.new(tx-botX,0,tz-botZ)
  local move=math.min(delta.Magnitude,dt*(now<botSlowUntil and 8 or 20))
  if delta.Magnitude>0.01 then botX+=delta.Unit.X*move; botZ+=delta.Unit.Z*move end
  local center=Vector3.new(botX,184.5,botZ+1)
  if ball.live and ball.last==1 and ball.p.Z< -2 and (ball.p-center).Magnitude<6.5 and ball.p.Y<188 and (ball.v.Y<0 or ball.bounces>0) and not Rules.returnFault(ball.bounces,ball.shots,Rules.inKitchen(center,1)) then
   local clean=perfect(now)
   if clean then ball.perfects+=1; ball.speed=Rules.returnSpeed(ball.speed,true,false) end
   ball.last=-1; ball.shots+=1
   local targetX=math.sin(now*0.7)*12
   launch(ball.p,Vector3.new(targetX,FLOOR,26),false)
  end
 end
 botBody.Position=Vector3.new(botX,184.2,botZ)
 botHead.Position=Vector3.new(botX,186.3,botZ)
 botPaddle.CFrame=CFrame.new(botX-1.8,184.4,botZ+1)*CFrame.Angles(0,0,0.2)
 for i,p in ipairs(botLegs) do p.Position=Vector3.new(botX+(i==1 and -0.6 or 0.6),182.4,botZ) end
 broadcast+=dt
 if broadcast>=0.05 then
  broadcast=0
  local target,t=landing()
  if ball.live and now-ball.bounceAt<=0.28 and ball.bouncePoint then
   target=ball.bouncePoint; t=0
  end
  for p,d in pairs(users) do
   state:FireClient(p,{
    p=ball.p,v=ball.v,g=ball.g,live=ball.live,landing=target,eta=t,
    green=ball.live and perfect(now),last=ball.last,bounces=ball.bounces,
    perfects=ball.perfects,speed=ball.speed,score=score,banner=banner,
    serveReady=serveReady,servingSide=servingSide,serveX=serveX,serverId=serverId,receiverId=receiverId,
    canServe=serveReady and (p.UserId==serverId or (hasBot and servingSide==-1 and p.UserId==receiverId)),
    mustBounce=ball.live and ball.shots<2 and ball.bounces==0,
    side=d.side,bot=hasBot,stamina=d.stamina,dive=math.max(0,d.diveAt-now),
    power=math.max(0,d.powerAt-now),slow=math.max(0,d.slowAt-now),
    armed=math.max(0,d.powerUntil-now),slowed=math.max(0,d.slowUntil-now)
   })
  end
 end
end)
