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
local users={}
local score={0,0}
local ball={p=Vector3.new(0,187,-28),v=Vector3.zero,g=GRAVITY,live=false,last=-1,bounces=0,perfects=0,bounceAt=-100}
local nextServe=os.clock()+3
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
local function occupant(side)
 for p,d in pairs(users) do if d.side==side then return p,d end end
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
local function launch(from,target,boost)
 local speedScale=1.05^ball.perfects*(boost and 1.22 or 1)
 -- Solve a clear arc at base speed, then scale time and gravity together.
 -- This preserves net clearance while velocity increases by exactly 5% per perfect.
 local distance=(Vector3.new(target.X,0,target.Z)-Vector3.new(from.X,0,from.Z)).Magnitude
 local duration=math.max(0.7,distance/BASE_SPEED)
 local vy=(FLOOR-from.Y+0.5*GRAVITY*duration*duration)/duration
 local crossing=(0-from.Z)/(target.Z-from.Z)
 if crossing>0 and crossing<1 then
  local tc=duration*crossing
  local netY=from.Y+vy*tc-0.5*GRAVITY*tc*tc
  if netY<185.2 then
   duration=math.sqrt(math.max(0.01,2*(185.2-from.Y-(FLOOR-from.Y)*crossing)/(GRAVITY*crossing*(1-crossing))))
   vy=(FLOOR-from.Y+0.5*GRAVITY*duration*duration)/duration
  end
 end
 ball.p=from
 ball.g=GRAVITY*speedScale*speedScale
 ball.v=Vector3.new((target.X-from.X)/duration,vy,(target.Z-from.Z)/duration)*speedScale
 ball.bounces=0; ball.bounceAt=-100; ball.live=true
end
local function point(winner,reason)
 if not ball.live then return end
 ball.live=false; ball.v=Vector3.zero; ball.perfects=0
 local index=winner==1 and 1 or 2
 score[index]+=1
 banner=(winner==1 and "HOME" or "AWAY").." POINT  /  "..reason
 nextServe=os.clock()+2.5
 feedback:FireAllClients(banner,"point")
 if score[index]>=11 and math.abs(score[1]-score[2])>=2 then
  banner=(winner==1 and "HOME" or "AWAY").." WINS!  /  New game in 6 seconds"
  feedback:FireAllClients(banner,"point")
  nextServe=os.clock()+6
  ball.resetScore=true
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
end
local function addPlayer(p)
 if users[p] then return end
 local side=not occupant(1) and 1 or (not occupant(-1) and -1 or 0)
 users[p]={side=side,stamina=100,lastSwing=0,diveAt=0,powerAt=0,slowAt=0,powerUntil=0,slowUntil=0,lastInput=0}
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
  for waiting,d in pairs(users) do
   if d.side==0 then d.side=leaving.side; waiting:SetAttribute("CourtSide",d.side); if waiting.Character then task.spawn(spawnCharacter,waiting,waiting.Character) end; break end
  end
  if not occupant(1) then
   local remaining,d=occupant(-1)
   if remaining then
    d.side=1; remaining:SetAttribute("CourtSide",1)
    if remaining.Character then task.spawn(spawnCharacter,remaining,remaining.Character) end
   end
  end
 end
end)
input.OnServerEvent:Connect(function(p,action,moveAtImpact)
 local d=users[p]
 if not d or d.side==0 or type(action)~="string" then return end
 local now=os.clock()
 -- Remote flood protection does not impose a gameplay cooldown on perfect returns.
 if now-d.lastInput<0.015 then return end
 d.lastInput=now
 local r,h=rootOf(p)
 if not r or not h or h.Health<=0 then return end
 if action=="Dive" then
  if now<d.diveAt or d.stamina<35 then return end
  d.stamina-=35; d.diveAt=now+1.6
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
  local opponent,od=occupant(-d.side)
  if opponent then od.slowUntil=now+2.5; tell(opponent,"SLOWED  /  2.5s","slow") else botSlowUntil=now+2.5 end
  tell(p,"OPPONENT SLOWED","power")
 elseif action=="Swing" then
  if now<d.lastSwing then return end
  local face=p.Character:FindFirstChild("PaddleFace")
  local center=face and face.Position or r.Position
  local distance=(ball.p-center).Magnitude
  local valid=ball.live and ball.last~=d.side and ball.p.Z*d.side>=-1 and distance<=9
  local clean=valid and perfect(now)
  d.lastSwing=clean and now or now+0.28
  feedback:FireAllClients(p.UserId,"swing")
  if not valid then tell(p,"MOVE INTO THE BALL","miss"); return end
  if clean then ball.perfects+=1 end
  local moving=Vector3.zero
  if typeof(moveAtImpact)=="Vector3" and moveAtImpact.X==moveAtImpact.X and moveAtImpact.Z==moveAtImpact.Z then
   local horizontal=Vector3.new(moveAtImpact.X,0,moveAtImpact.Z)
   if horizontal.Magnitude<=1.1 then moving=horizontal.Magnitude>1 and horizontal.Unit or horizontal end
  end
  -- World-space movement is inherited at impact; position also influences placement.
  local targetX=math.clamp(r.Position.X*0.3+moving.X*17,-18,18)
  local targetDepth=math.clamp(27-moving.Z*d.side*10,17,37)
  local powered=now<d.powerUntil
  d.powerUntil=0
  ball.last=d.side
  launch(ball.p,Vector3.new(targetX,FLOOR,-d.side*targetDepth),powered)
  tell(p,clean and "PERFECT!  +5%" or (powered and "POWER RETURN!" or "CLEAN RETURN"),clean and "perfect" or "hit")
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
   if d.side~=0 then
    local x=math.clamp(r.Position.X,-24,24)
    local z=d.side*math.clamp(r.Position.Z*d.side,2.5,46)
    if math.abs(x-r.Position.X)>0.1 or math.abs(z-r.Position.Z)>0.1 or r.Position.Y<178 then
     r.CFrame=CFrame.new(x,math.max(r.Position.Y,184),z)*r.CFrame.Rotation
    end
   end
  end
 end
 local hasBot=occupant(-1)==nil
 for _,p in ipairs(bot:GetChildren()) do if p:IsA("BasePart") then p.Transparency=hasBot and 0 or 1 end end
 tag.Enabled=hasBot
 if not ball.live and now>=nextServe and occupant(1) then
  if ball.resetScore then score={0,0}; ball.resetScore=false end
  ball.last=-1; ball.perfects=0
  launch(Vector3.new(botX,187,-28),Vector3.new(0,FLOOR,27),false)
  banner="RALLY  /  Move into your shot"
 end
 if ball.live then
  accumulator+=math.min(dt,0.1)
  while accumulator>=1/120 and ball.live do
   local step=1/120
   accumulator-=step
   local previous=ball.p
   ball.p+=ball.v*step+Vector3.new(0,-0.5*ball.g*step*step,0)
   ball.v+=Vector3.new(0,-ball.g*step,0)
   if previous.Z*ball.p.Z<=0 and math.abs(ball.p.X)<21 and ball.p.Y<184.65 then
    point(-ball.last,"Net")
   elseif ball.p.Y<=FLOOR then
    if ball.bounces>=1 then
     point(ball.last,"Double bounce")
    elseif math.abs(ball.p.X)>20.5 or math.abs(ball.p.Z)>40.5 then
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
 if hasBot then
  local predicted=landing()
  local tx=ball.live and ball.last==1 and math.clamp(predicted.X,-18,18) or 0
  local tz=ball.live and ball.last==1 and math.clamp(predicted.Z,-37,-8) or -28
  local delta=Vector3.new(tx-botX,0,tz-botZ)
  local move=math.min(delta.Magnitude,dt*(now<botSlowUntil and 8 or 20))
  if delta.Magnitude>0.01 then botX+=delta.Unit.X*move; botZ+=delta.Unit.Z*move end
  local center=Vector3.new(botX,184.5,botZ+1)
  if ball.live and ball.last==1 and ball.p.Z< -2 and (ball.p-center).Magnitude<6.5 and ball.p.Y<188 and (ball.v.Y<0 or ball.bounces>0) then
   local clean=perfect(now)
   if clean then ball.perfects+=1 end
   ball.last=-1
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
    perfects=ball.perfects,speed=1.05^ball.perfects,score=score,banner=banner,
    side=d.side,bot=hasBot,stamina=d.stamina,dive=math.max(0,d.diveAt-now),
    power=math.max(0,d.powerAt-now),slow=math.max(0,d.slowAt-now),
    armed=math.max(0,d.powerUntil-now),slowed=math.max(0,d.slowUntil-now)
   })
  end
 end
end)