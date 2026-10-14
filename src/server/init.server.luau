-- Server-authoritative arcade pickleball.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
game:GetService("StarterPlayer").EnableMouseLockOption=false
require(script:WaitForChild("World")).build()
local Spectator=require(script:WaitForChild("Spectator"))
local Lobby=require(script:WaitForChild("Lobby"))
Lobby.build()
require(script:WaitForChild("DayNightCycle")).start()
local folder=ReplicatedStorage:FindFirstChild("PaddleUp") or Instance.new("Folder")
folder.Name="PaddleUp"; folder.Parent=ReplicatedStorage
local function remote(name)
 local r=folder:FindFirstChild(name) or Instance.new("RemoteEvent")
 r.Name=name; r.Parent=folder
 return r
end
local input,state,feedback=remote("Input"),remote("State"),remote("Feedback")
local session=remote("Session")
local augmentRemote=remote("Augment")
local Augments=require(script:WaitForChild("Augments"))
local courtVariant=nil
local draft=nil
local draftSerial=0
local draftDue=false
local rallies=0
local augmentRandom=Random.new()
local courtMode=nil
local FLOOR,GRAVITY,BASE_SPEED=181.7,45,56
local WALK_SPEED,SLOWED_SPEED=18,10
local rulesModule=script:WaitForChild("MatchRules")
local Rules=require(rulesModule)
-- Existing Studio sessions may not have picked up the new Rojo shared mapping.
local shared=ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder")
shared.Name="Shared"; shared.Parent=ReplicatedStorage
if not shared:FindFirstChild("MatchRules") then rulesModule:Clone().Parent=shared end
local users={}
local rotation=require(script:WaitForChild("ServeRotation")).new()
local score=rotation.score
local Comeback=require(script:WaitForChild("Comeback"))
local comeback=Comeback.new()
local joinSerial=0
local lastHitter={}
local ball={p=Vector3.new(0,187,-28),v=Vector3.zero,g=GRAVITY,live=false,last=-1,bounces=0,perfects=0,speed=1,bounceAt=-100}
local nextServe=0
local matchIntro=nil
local introSerial=0
local introUntil=0
local serveDeadline
local servingSide,serveReady,serveX=1,false,10
local serverId,receiverId
ball.shots=0
local banner="Welcome to Skyline Club"
local function resetAugments()
 draft=nil; draftDue=courtVariant=="Augmented"; rallies=0
 for p,d in pairs(users) do
  d.augments={}; d.augmentNames={}; d.augmentPulses={}; d.augmentActive={}; d.augmentMatch={}; d.augmentRally=Augments.newRally()
  p:SetAttribute("AugmentDraftOpen",false)
  augmentRemote:FireClient(p,{kind="reset"})
 end
end
local function chooseAugment(p,id)
 local offer=draft and draft.offers[p]
 local d=users[p]
 if not d or d.side==0 then return end
 local card=Augments.choose(offer,id,d.augments)
 if not card then return end
 draft.offers[p]=nil
 table.insert(d.augmentNames,card.name)
 augmentRemote:FireClient(p,{kind="chosen",name=card.name,count=#d.augmentNames,stats=d.augments,names=d.augmentNames,card=card})
end
augmentRemote.OnServerEvent:Connect(function(p,serial,id)
 if draft and serial==draft.id then chooseAugment(p,id) end
end)
local function updateDraft(now)
 if draftDue and not draft and not ball.live and now>=introUntil and now>=nextServe then
  if ball.resetScore then rotation:reset(); score=rotation.score; ball.resetScore=false; comeback=Comeback.new() end
  local roster={}
  local home,away=false,false
  for p,d in pairs(users) do
   if d.side~=0 then table.insert(roster,p); if d.side==1 then home=true else away=true end end
  end
  if not home or (not away and courtMode~="Practice") then return end
  table.sort(roster,function(a,b) return a.UserId<b.UserId end)
  local builds={}
  for index,p in ipairs(roster) do builds[index]=users[p].augments end
  local tier,offers=Augments.deal(augmentRandom,#roster,builds)
  draftSerial+=1
  draft={id=draftSerial,endsAt=now+Augments.DURATION,offers={}}
  draftDue=false; serveReady=false; serveDeadline=nil
  for index,p in ipairs(roster) do
   draft.offers[p]=offers[index]
   users[p].chargeAt=nil; users[p].diveUntil=0
   if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
   p:SetAttribute("AugmentDraftOpen",true)
   augmentRemote:FireClient(p,{kind="offer",id=draft.id,tier=tier,cards=offers[index],endsAt=workspace:GetServerTimeNow()+Augments.DURATION})
  end
 end
 if draft then
  if now>=draft.endsAt then
   for p,offer in pairs(draft.offers) do chooseAugment(p,offer[1].id) end
  end
  if not next(draft.offers) then
   draft=nil; nextServe=now+1
   for p in pairs(users) do
    p:SetAttribute("AugmentDraftOpen",false)
    augmentRemote:FireClient(p,{kind="close"})
   end
  end
 end
end
local botSlowUntil=0
local botStunUntil=0
local botX,botZ=0,-28
local botRandom=Random.new()
local botShotId,botReactAt,botThinkAt,botSwingAt=nil,0,0,0
local botTarget=Vector3.new(0,0,-28)
local botError=Vector3.zero
local botAttempted=false
local botStride,botMoving=0,false
local world=workspace:WaitForChild("PaddleUp")
local powerups=require(script:WaitForChild("Powerups")).new(world,function(player,kind)
 player:SetAttribute("LastCollectedPowerup",kind)
 player:SetAttribute("PowerupsCollected",(player:GetAttribute("PowerupsCollected") or 0)+1)
 feedback:FireAllClients({userId=player.UserId,text="POWERUP COLLECTED / TEST",tone="good"},"playerText")
end)
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
 table.sort(team,function(a,b)
  if users[a].slot==users[b].slot then return users[a].joined<users[b].joined end
  return users[a].slot<users[b].slot
 end)
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
local function teamName(side)
 local names={}
 for _,p in ipairs(teamPlayers(side)) do table.insert(names,p.DisplayName) end
 return #names>0 and table.concat(names," + ") or (side==-1 and "Practice Partner" or "Waiting for players")
end
local function syncServing()
 servingSide=rotation.side; serverId=rotation.serverId; receiverId=rotation:receiverId(); serveX=rotation:serveX()
end
local function rosterChanged()
 comeback=Comeback.new()
 powerups:reset()
 resetAugments()
 local home,away={},{}
 for _,p in ipairs(teamPlayers(1)) do table.insert(home,p.UserId) end
 for _,p in ipairs(teamPlayers(-1)) do table.insert(away,p.UserId) end
 if courtMode=="Practice" and #home>0 and #away==0 then away={0} end -- Bot service follows singles rules.
 rotation:setTeams(home,away)
 if #home==0 and #away==0 then rotation:reset(); score=rotation.score end
 syncServing()
 ball.live=false; ball.v=Vector3.zero; ball.speed=1; ball.perfects=0
 ball.outLanding=nil; serveReady=false; serveDeadline=nil; nextServe=os.clock()+1
 introUntil=0; matchIntro=nil
 if #home>0 and #away>0 then
  introSerial+=1
  introUntil=os.clock()+9.5
  nextServe=introUntil
  local function portraits(side)
   local result={}
   for _,player in ipairs(teamPlayers(side)) do
    table.insert(result,{userId=player.UserId,name=player.DisplayName})
   end
   if side==-1 and courtMode=="Practice" and #result==0 then
    table.insert(result,{userId=0,name="Practice Partner",bot=true})
   end
   return result
  end
  matchIntro={id=introSerial,endsAt=workspace:GetServerTimeNow()+9.5,home=portraits(1),away=portraits(-1)}
 end
 for p,d in pairs(users) do
  d.diveUntil=0; d.divePoseUntil=0; d.volleyPending=false; d.chargeAt=nil
  if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  if introUntil>0 and d.side~=0 and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
   local primary=p.UserId==(d.side==servingSide and serverId or receiverId)
   local position=Rules.startPosition(d.side,servingSide,serveX,primary)
   p.Character:PivotTo(CFrame.lookAt(position,Vector3.new(position.X,185,0)))
   p.Character.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
  end
 end
 if introUntil>0 and courtMode=="Practice" then botX=-serveX; botZ=-46 end
 banner="TEAMS UPDATED / PREPARING SERVE"
 feedback:FireAllClients({title="Teams Updated",fault="Preparing the next serve"},"rallyResult")
end
local function rootOf(p)
 local c=p.Character
 return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end
local function tell(p,text,kind)
 kind=kind or "info"
 local tone=(kind=="perfect" or kind=="slam" or kind=="power") and "good"
  or (kind=="miss" or kind=="fault" or kind=="slow") and "bad" or "neutral"
 feedback:FireAllClients({userId=p.UserId,text=text,tone=tone},"playerText")
 if kind=="fault" then feedback:FireClient(p,text,kind) end
end
local function activateAugment(p,id,duration)
 local d=users[p]
 if not d or not Augments.has(d.augments,id) then return end
 d.augmentPulses=d.augmentPulses or {}
 local now=os.clock()
 local previous=d.augmentPulses[id] or 0
 d.augmentPulses[id]=now+(duration or 0.85)
 if previous>now then return end
 local tier=1
 for _,card in ipairs(Augments.catalog) do if card.id==id then tier=card.tier; break end end
 feedback:FireAllClients({userId=p.UserId,id=id,tier=tier},"augmentFX")
end
local function landing()
 if not ball.live then return ball.p,0 end
 local h=math.max(0,ball.p.Y-FLOOR)
 local gravity=ball.flightGravity or GRAVITY
 local t=Rules.ballLandingTime(h,ball.v.Y,gravity,ball.lob,ball.bounces>0)
 if ball.offensive then
  if ball.p.Z*ball.last<=0 then
   t=Rules.ballLandingTime(h,ball.v.Y,gravity*1.8,ball.lob,ball.bounces>0)
  elseif ball.v.Z~=0 then
   local crossing=-ball.p.Z/ball.v.Z
   if crossing>=0 and crossing<t then
    local at,velocity=Rules.advanceBall(ball.p,ball.v,gravity,crossing,ball.lob,ball.bounces>0)
    t=crossing+Rules.ballLandingTime(at.Y-FLOOR,velocity.Y,gravity*1.8,ball.lob,ball.bounces>0)
   end
  end
 end
 return ball.p+Vector3.new(ball.v.X*t,-h,ball.v.Z*t),t
end
local function perfect(now,d)
 local _,t=landing()
 return Augments.perfect(d and d.augments,t,now-ball.bounceAt)
end
local function lobCrossesSlamZone(from,velocity,gravity,duration)
 -- Classify the whole shot at launch, independent of a receiver's current position.
 -- A blue arc advertises an overhead opportunity, not a guaranteed legal hit.
 for step=0,120 do
  local t=duration*step/120
  local position=Rules.advanceBall(from,velocity,gravity,t,true,false)
  local side=-ball.last
  local root=Vector3.new(math.clamp(position.X,-Rules.HALF_WIDTH,Rules.HALF_WIDTH),184,side*(Rules.KITCHEN+2))
  local headTop,armLength=187,4
  if Rules.overheadReach(position,root,headTop+Rules.SLAM_MIN_HEIGHT,headTop+armLength+Rules.SLAM_EXTRA_HEIGHT)
   and (position-(root+Vector3.new(0,0,-side*2))).Magnitude<=Rules.SLAM_RANGE then return true end
 end
 return false
end
local function launch(from,target,boost,lob,slam,momentum,soft,mishit,charge,contact)
 local rallyScale=contact and contact.uncapped and 1 or ball.speed
 local speedScale=(slam and Rules.slamSpeedScale(rallyScale) or rallyScale)*(boost and 1.22 or 1)*(1+0.12*(momentum or 0))
 if not slam and not soft then speedScale*=1+0.22*(charge or 0) end
 -- Speed changes flight time; lobs use heavier gravity after their apex.
 if soft then speedScale*=0.65 end
 local distance=(Vector3.new(target.X,0,target.Z)-Vector3.new(from.X,0,from.Z)).Magnitude
 local gravity=GRAVITY
 local duration=slam and math.max(0.12,math.min(distance/(BASE_SPEED*1.8),math.sqrt(2*math.max(0.1,from.Y-FLOOR)/gravity)*0.75)) or math.max(0.7,distance/BASE_SPEED)
 if lob then duration=math.max(duration*1.35,1.5) end
 duration=duration/math.max(0.1,speedScale)
 if contact and contact.minDuration then duration=math.max(duration,contact.minDuration) end
 local vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
 local crossing=(0-from.Z)/(target.Z-from.Z)
 local crossingX=from.X+(target.X-from.X)*crossing
 local aroundPost=crossing>0 and crossing<1 and math.abs(from.X)>21 and math.abs(crossingX)>21
 if not aroundPost and not mishit and crossing>0 and crossing<1 then
  local tc=duration*crossing
  local netY=from.Y+vy*tc-0.5*gravity*tc*tc
  if netY<185.2 then
   duration=math.sqrt(math.max(0.01,2*(185.2-from.Y-(FLOOR-from.Y)*crossing)/(gravity*crossing*(1-crossing))))
   vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
  end
 end
 if lob then
  vy=Rules.lobLaunchY(from.Y-FLOOR,duration,GRAVITY)
  if not mishit and crossing>0 and crossing<1 then
   for _=1,100 do
    local sample=Rules.advanceBall(from,Vector3.new(0,vy,0),GRAVITY,duration*crossing,true,false)
    if sample.Y>=185.2 then break end
    duration*=1.03
    vy=Rules.lobLaunchY(from.Y-FLOOR,duration,GRAVITY)
   end
  end
 end
 if mishit then
  -- Keep horizontal aim, but send the ball below net height without clearance assist.
  if crossing>0 and crossing<1 then
   local tc=duration*crossing
   vy=(183.3-from.Y+0.5*gravity*tc*tc)/tc
  else vy=math.min(vy,-3) end
 end
 -- Preserve the landing target while bounding the complete serve launch velocity.
 if contact and contact.maxVelocity then
  for _=1,100 do
   local velocity=Vector3.new((target.X-from.X)/duration,vy,(target.Z-from.Z)/duration)
   if velocity.Magnitude<=contact.maxVelocity then break end
   duration*=1.01
   vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
  end
 end
 ball.offensive=contact and contact.offensive or false
 if ball.offensive and crossing>0 and crossing<1 then
  vy+=0.4*GRAVITY*(duration-duration*crossing)^2/duration
 end
 ball.heavy=contact and contact.heavy or false
 ball.trackingHiddenUntil=contact and contact.deceptive and os.clock()+0.5 or 0
 ball.trackingGlitchUntil=contact and contact.afterimage and os.clock()+0.65 or 0
 ball.spin=contact and contact.spin or nil
 ball.sliceBoost=contact and contact.sliceBoost or false
 ball.soft=soft; ball.slam=slam==true
 ball.atp=aroundPost and contact and contact.atp or false
 ball.deadly=contact and contact.deadly or false
 ball.hitter=contact and contact.userId or nil
 ball.lob=lob==true
 ball.p=from
 ball.g=ball.lob and vy<=0 and GRAVITY*Rules.LOB_GRAVITY_SCALE or GRAVITY
 ball.v=Vector3.new((target.X-from.X)/duration,vy,(target.Z-from.Z)/duration)
 if contact and contact.reflectedSpeed then
  local height=FLOOR-from.Y
  -- Slow calculated returns still reach the court at the specified speed.
  local reachGravity=contact.reflectedSpeed^2/math.max(0.01,math.sqrt(distance^2+height^2)+height)
  gravity=math.min(gravity,reachGravity*0.95)
  local low,high=Augments.flightTimes(distance,height,contact.reflectedSpeed,gravity)
  if low and low>0 then
   duration=low
   local y=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
   local tc=duration*crossing
   if crossing>0 and crossing<1 and from.Y+y*tc-0.5*gravity*tc*tc<185.2 then duration=high end
   ball.v=Vector3.new((target.X-from.X)/duration,(FLOOR-from.Y+0.5*gravity*duration*duration)/duration,(target.Z-from.Z)/duration)
  end
 end
 -- Preserve the solved arc while changing travel speed, including net clearance.
 local shotMultiplier=contact and contact.speedMultiplier or 1
 local multiplier=shotMultiplier*(contact and contact.uncapped and ball.speed or 1)
 ball.v*=multiplier
 ball.flightGravity=gravity*multiplier*multiplier
 ball.g=ball.flightGravity*(ball.lob and ball.v.Y<=0 and Rules.LOB_GRAVITY_SCALE or 1)
 ball.shotMultiplier=shotMultiplier
 ball.peakSpeed=math.max(ball.peakSpeed or 1,ball.speed*shotMultiplier)
 ball.launchPosition=from; ball.launchVelocity=ball.v; ball.launchedAt=os.clock()
 ball.shotId=(ball.shotId or 0)+1
 ball.slamLob=ball.lob and lobCrossesSlamZone(from,ball.v,ball.flightGravity,duration/multiplier)
 ball.bounces=0; ball.bounceAt=-100; ball.live=true
 -- All viewers receive the same accepted contact, including practice-partner hits.
 contact=contact or {}
 contact.position=from; contact.direction=ball.v.Unit; contact.speed=ball.speed*shotMultiplier
 contact.slam=slam==true; contact.powered=boost==true; contact.charge=charge or 0; contact.soft=soft
 feedback:FireAllClients(contact,"ballHit")
end
local function point(winner,reason)
 if not ball.live then return end
 local server=serverId and Players:GetPlayerByUserId(serverId)
 local serverData=server and users[server]
 if ball.shots==0 and winner==-servingSide and serverData
  and Augments.retryServe(serverData.augments,serverData.augmentMatch) then
  activateAugment(server,"secondServe",1.5)
  serverData.stamina=100
  ball.live=false; ball.v=Vector3.zero; serveReady=false; serveDeadline=nil; nextServe=os.clock()+1
  tell(server,"SECOND SERVE / MULLIGAN + FULL STAMINA","perfect")
  return
 end
 for player,data in pairs(users) do
  if data.side==winner then
   local root=rootOf(player)
   local wins=data.augmentMatch.speedWins or 0
   local reach=data.augmentMatch.reachStacks or 0
   Augments.terminalWin(data.augments,data.augmentMatch,ball.peakSpeed or ball.speed)
   Augments.netWin(data.augments,data.augmentMatch,root and math.abs(root.Position.X)<=20
    and root.Position.Z*data.side<=Rules.KITCHEN+4)
   if (data.augmentMatch.speedWins or 0)>wins then activateAugment(player,"terminalVelocity",1.5) end
   if (data.augmentMatch.reachStacks or 0)>reach then activateAugment(player,"vampiricReach",1.5) end
  end
 end
 ball.live=false; ball.v=Vector3.zero; ball.perfects=0; ball.speed=1
 local index=winner==1 and 1 or 2
 local outcome=rotation:award(winner)
 local scored=outcome=="point"
 local previousComeback=comeback.side
 Comeback.update(comeback,score,false)
 syncServing()
 banner="TEAM "..(servingSide==1 and "1" or "2")..(scored and " POINT / " or outcome=="secondServer" and " SECOND SERVER / " or " SIDE OUT / ")..reason
 serveReady=false; serveDeadline=nil
 for p,d in pairs(users) do d.augmentRally.stunUntil=0; d.augmentRally.burstUntil=0; d.diveUntil=0; d.divePoseUntil=0; d.volleyPending=false; d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end end
 nextServe=os.clock()+2.5
 local scorer=lastHitter[winner] or occupant(winner)
 local scorerName=scorer and scorer.DisplayName or "Practice Partner"
 local faultNames={
  ["Double bounce"]="Double Bounce!",["Net"]="Net Fault!",["Out"]="Out!",
  ["Short return"]="Short Return!",["Kitchen volley fault"]="Foot Fault!",
  ["Two-bounce rule: let the ball bounce"]="Two-Bounce Fault!",
  ["Wrong receiver: the diagonal player must return the serve"]="Wrong Receiver!",
  ["Serve fault: land in the diagonal service court"]="Serve Fault!",
  ["Rally over"]="Rally Over!",
 }
 feedback:FireAllClients({title=scored and (scorerName.." Scored for Team "..index.."!") or outcome=="secondServer" and "Second Server!" or "Side Out!",fault=faultNames[reason] or (reason.."!")},"rallyResult")
 if scored and score[index]>=11 and math.abs(score[1]-score[2])>=2 then
  banner="TEAM "..index.." WINS!  /  New game in 6 seconds"
  feedback:FireAllClients(banner,"point")
  nextServe=os.clock()+6
  ball.resetScore=true
  Comeback.update(comeback,score,true)
 end
 if previousComeback~=comeback.side then
  feedback:FireAllClients(comeback.side~=0 and "COMEBACK! Team "..(comeback.side==1 and "1" or "2").." gains +15% movement, reach and hit speed until tied." or "COMEBACK BOOST ENDED","point")
 end
 if courtVariant=="Augmented" then
  rallies+=1
  if ball.resetScore then resetAugments()
  elseif rallies%3==0 then draftDue=true end
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
 if not r or not h or p.Character~=c then return end
 Spectator.leave(p)
 -- Release lobby furniture before relocating an avatar to the court or spectator deck.
 local seatedAt=h.SeatPart
 h.Sit=false
 if seatedAt then
  local weld=seatedAt:FindFirstChild("SeatWeld")
  if weld and weld:IsA("Weld") and weld.Part1 and weld.Part1:IsDescendantOf(c) then weld:Destroy() end
 end
 h.WalkSpeed=WALK_SPEED; h.UseJumpPower=true; h.JumpPower=38
 local z=d.side==0 and 58 or d.side*28
 c:PivotTo(d.mode=="Lobby" and Lobby.Spawn or CFrame.lookAt(Vector3.new(d.side==0 and 40 or 0,185,z),Vector3.new(0,185,0)))
 if d.side~=0 and os.clock()<introUntil then
  local primary=p.UserId==(d.side==servingSide and serverId or receiverId)
  local position=Rules.startPosition(d.side,servingSide,serveX,primary)
  c:PivotTo(CFrame.lookAt(position,Vector3.new(position.X,185,0)))
 end
 r.AssemblyLinearVelocity=Vector3.zero; r.AssemblyAngularVelocity=Vector3.zero
 for _,name in ipairs({"PaddleFace","PaddleGrip"}) do
  local existing=c:FindFirstChild(name)
  if existing and d.side==0 then existing:Destroy() end
 end
 if d.side~=0 and not c:FindFirstChild("PaddleFace") then paddle(c) end
 d.kitchenTouched=false; d.volleyPending=false; d.diveUntil=0; d.divePoseUntil=0; d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
 if d.side~=0 and not ball.live then serveReady=false; serveDeadline=nil end
 if d.mode=="Spectate" then Spectator.enter(p,c) end
end
local function addPlayer(p)
 if users[p] then return end
 local side=0
 joinSerial+=1
 users[p]={augments={},augmentNames={},augmentMatch={},augmentRally=Augments.newRally(),mode="Lobby",sessionAt=0,side=side,slot=side~=0 and availableSlot(side) or 0,joined=joinSerial,stamina=100,staminaRecoveryAt=0,lastSwing=0,diveAt=0,powerAt=0,slowAt=0,powerUntil=0,slowUntil=0,lastInput=0}
 p:SetAttribute("CourtSide",side)
 p:SetAttribute("SessionMode","Lobby")
 if side~=0 then rosterChanged() end
 p.CharacterRemoving:Connect(function() Spectator.leave(p) end)
 p.CharacterAppearanceLoaded:Connect(function(c)
  if users[p] and users[p].mode=="Spectate" and p.Character==c then spawnCharacter(p,c) end
 end)
 p.CharacterAdded:Connect(function(c) spawnCharacter(p,c) end)
 if p.Character then task.spawn(spawnCharacter,p,p.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
for _,p in ipairs(Players:GetPlayers()) do addPlayer(p) end
-- Admission to the existing roster, with no matchmaking or additional court simulation.
local function leaveCourt(p)
 local d=users[p]
 if not d then return end
 local active=d.side~=0
 d.side=0; d.slot=0
 d.variant=nil; p:SetAttribute("MatchVariant",nil)
 d.diveUntil=0; d.divePoseUntil=0; d.volleyPending=false; d.serveChargeAt=nil; d.chargeAt=nil; d.chargeCooldownBlocked=nil
 d.powerUntil=0; d.slowUntil=0
 if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
 p:SetAttribute("CourtSide",0)
 if not active then return end
 if not occupant(1) then
  local remaining,other=occupant(-1)
  if remaining then
   other.slot=availableSlot(1); other.side=1; remaining:SetAttribute("CourtSide",1)
   if remaining.Character then task.spawn(spawnCharacter,remaining,remaining.Character) end
  end
 end
 if not occupant(1) and not occupant(-1) then
  courtMode=nil; courtVariant=nil; rotation:reset(); score=rotation.score; ball.resetScore=false; comeback=Comeback.new()
 end
 rosterChanged()
end
session.OnServerEvent:Connect(function(p,mode,variant)
 local d=users[p]
 if not d or type(mode)~="string" then return end
 if mode~="Lobby" and mode~="Spectate" and mode~="Practice" and mode~="1V1" and mode~="2V2" and mode~="1V2" then return end
 if mode~="Lobby" and mode~="Spectate" and variant~="PowerUp" and variant~="Augmented" then
  session:FireClient(p,false,"Choose Power-Up or Augmented first."); return
 end
 local now=os.clock()
 if now-d.sessionAt<0.5 then session:FireClient(p,false,"Please wait a moment before switching."); return end
 d.sessionAt=now
 if mode==d.mode and (d.side==0 or variant==d.variant) then session:FireClient(p,true,"Already connected."); return end
 if mode=="Lobby" or mode=="Spectate" then
  leaveCourt(p); d.mode=mode
 else
  -- Validate before leaving, so a rejected choice never disrupts a live match.
  if courtMode and (courtMode~=mode or courtVariant~=variant) then
   session:FireClient(p,false,"Court is in "..courtMode.." / "..courtVariant..". Spectate or wait for the court to empty.")
   return
  end
  local homeLimit=mode=="2V2" and 2 or 1
  local awayLimit=(mode=="2V2" or mode=="1V2") and 2 or 1
  local home,away=#teamPlayers(1),#teamPlayers(-1)
  if (mode=="Practice" and home+away>0) or (home>=homeLimit and away>=awayLimit) then
   session:FireClient(p,false,"Court is full. Choose Spectate to watch.")
   return
  end
  courtMode=mode
  courtVariant=variant; d.variant=variant; p:SetAttribute("MatchVariant",variant)
  d.side=(home<homeLimit and (home<=away or away>=awayLimit)) and 1 or -1
  d.slot=availableSlot(d.side); d.mode=mode
  p:SetAttribute("CourtSide",d.side)
  d.stamina=100; d.powerUntil=0; d.slowUntil=0
  rosterChanged()
 end
 p:SetAttribute("SessionMode",d.mode)
 if p.Character then task.spawn(spawnCharacter,p,p.Character) end
 session:FireClient(p,true,"Connected.")
end)
Players.PlayerRemoving:Connect(function(p)
 Spectator.leave(p)
 leaveCourt(p)
 users[p]=nil
end)
local function prepareServe()
 if ball.resetScore then rotation:reset(); score=rotation.score; ball.resetScore=false; comeback=Comeback.new() end
 syncServing()
 if not occupant(1) or (courtMode~="Practice" and not occupant(-1)) then return end
 table.clear(lastHitter)
 botStunUntil=0
 for _,d in pairs(users) do d.augmentRally=Augments.newRally(); d.diveHeld=false end
 for p,d in pairs(users) do
  local r,h=rootOf(p)
  if d.side~=0 and r and h and h.Health>0 then
   local primary=p.UserId==(d.side==servingSide and serverId or receiverId)
   local position=Rules.startPosition(d.side,servingSide,serveX,primary)
   p.Character:PivotTo(CFrame.lookAt(position,Vector3.new(position.X,185,0)))
   r.AssemblyLinearVelocity=Vector3.zero
   d.diveUntil=0; d.divePoseUntil=0; d.volleyPending=false; d.kitchenTouched=false; d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  end
 end
 if servingSide==-1 and not occupant(-1) then botX=serveX; botZ=-46
 else botX=-serveX; botZ=-46 end
 botShotId=nil; botAttempted=false; botSwingAt=0
 botTarget=Vector3.new(botX,0,botZ)
 ball.outLanding=nil; ball.peakSpeed=1
 ball.p=Vector3.new(serveX,184,servingSide*46)
 ball.v=Vector3.zero; ball.speed=1; ball.perfects=0; ball.shots=0
 ball.bounces=0; ball.bounceAt=-100; ball.last=servingSide
 serveReady=true
 serveDeadline=workspace:GetServerTimeNow()+Rules.SERVE_TIMEOUT
 banner="TEAM "..(servingSide==1 and "1" or "2").." / SERVER "..rotation.number.." TO SERVE"
end
local function facingTarget(from,r,side,depth)
 local direction,momentum=Rules.shotAim(r.CFrame,r.AssemblyLinearVelocity,from)
 depth+=momentum*4
 -- Facing plus a bounded movement offset; out shots remain possible.
 local distance=math.abs(-side*depth-from.Z)/math.max(0.25,math.abs(direction.Z))
 return from+direction*math.clamp(distance,12,110),momentum
end
local function serve(p,d,r,h)
 if not serveReady then return end
 if os.clock()<d.lastSwing then return end
 if not serveDeadline or workspace:GetServerTimeNow()>=serveDeadline then return end
 if not d.serveChargeAt then return end
 local _,offset,accuracy,grade=Rules.serveTiming(d.serveChargeAt,workspace:GetServerTimeNow())
 local botServing=servingSide==-1 and not occupant(-1)
 if p.UserId~=serverId and not (botServing and p.UserId==receiverId) then
  tell(p,"WAIT FOR THE DESIGNATED SERVER","info"); return
 end
 local from=Vector3.new(serveX,184,servingSide*46)
 if botServing then from=Rules.heldBallPosition(bot) or from end
 if not botServing then
  if not Rules.servePositionValid(r.Position,d.side,serveX,h.FloorMaterial~=Enum.Material.Air) then
   tell(p,"Foot Fault! Serve from behind the baseline on the marked side.","fault"); return
  end
  from=Rules.heldBallPosition(p.Character) or Vector3.new(r.Position.X,184,r.Position.Z)
 end
 if not botServing then
  lastHitter[servingSide]=p
  if Augments.has(d.augments,"serveVolley") then d.augmentRally.burstUntil=os.clock()+3; activateAugment(p,"serveVolley",3) end
 end
 d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
 serveReady=false; serveDeadline=nil; ball.last=servingSide; ball.shots=0
 local target=Rules.timedServeTarget(servingSide,serveX,offset)
 ball.speed=Rules.servePower(offset+1)
 d.lastSwing=os.clock()+Rules.HIT_COOLDOWN
 p.Character:SetAttribute("HitReadyAt",workspace:GetServerTimeNow()+Rules.HIT_COOLDOWN)
 launch(from,Vector3.new(target.X,FLOOR,target.Z),false,false,false,0,nil,offset<Rules.SERVE_NET_OFFSET,0,{userId=not botServing and p.UserId or nil,maxVelocity=offset>=Rules.SERVE_NET_OFFSET and Rules.MAX_SERVE_VELOCITY or nil})
 feedback:FireClient(p,{grade=grade,offset=offset,accuracy=accuracy},"serveTiming")
 if not botServing then
  feedback:FireAllClients({userId=p.UserId,backhand=false,contact=from,direction=ball.v.Unit,charge=accuracy},"swing")
 end
 banner="SERVE  /  LET IT BOUNCE"
end
local function overheadStatus(p,r)
  local face=p.Character:FindFirstChild("PaddleFace")
  local center=face and face.Position or r.Position
  local distance=(ball.p-center).Magnitude
  local minY,maxY=Rules.slamBounds(p.Character,r)
  local overhead=Rules.contactInFront(ball.p,r.CFrame) and distance<=Rules.SLAM_RANGE and Rules.overheadReach(ball.p,r.Position,minY,maxY)
 return distance,overhead
end
local function kitchenLobWindow(p,d,r,overhead)
 return Rules.kitchenLobWindow(ball.lob,overhead,r.Position,d.side)
end
local function slamReady(p,d,now)
 local r,h=rootOf(p)
 if not r or not h or h.Health<=0 or d.side==0 then return false end
 if not ball.live or ball.last==d.side or ball.p.Z*d.side< -1 then return false end
 if ball.shots==0 and receiverId and p.UserId~=receiverId then return false end
 if Rules.returnFault(ball.bounces,ball.shots,Rules.kitchenHitFault(r.Position,ball.p,d.side,now<d.diveUntil)) then return false end
 local _,overhead=overheadStatus(p,r)
 return overhead and (perfect(now,d) or kitchenLobWindow(p,d,r,overhead))
end
local function tryReturn(p,d,r,now,automatic,softRequested,charge,shotKind)
  charge=charge or 0
  local distance,overhead=overheadStatus(p,r)
  local backhand=r.CFrame:PointToObjectSpace(ball.p).X<0
  local bonus,extension=Augments.extraReach(d.augments,d.augmentMatch,backhand)
  local reach=(1+((d.augments and d.augments.reach) or 0)+bonus)*(Comeback.active(comeback,d.side) and Comeback.HIT or 1)
  local fire=Augments.onFire(d.augments,d.augmentRally,ball.shots+1)
  local guided=Augments.has(d.augments,"thirdShot") and ball.shots==1 and d.side==servingSide
  local feint=shotKind=="Lob" and d.chargeAt~=nil and overhead and Augments.has(d.augments,"baitSwitch")
  local shield=shotKind=="Deflect"
  local incomingSpeed=ball.v.Magnitude
  local diving=now<(d.divePoseUntil or d.diveUntil or 0)
  local deceptive=not shield and d.diveHeld and Augments.has(d.augments,"deceptiveDrop")
  local offensive=not shield and diving and Augments.has(d.augments,"offensiveDive")
  local heavy=Augments.apex(d.augments,ball.bounces,ball.v.Y,ball.g or GRAVITY)
  local grounded=p.Character.Humanoid.FloorMaterial~=Enum.Material.Air
  if Augments.warden(d.augments,r.Position.Z*d.side,r.Position.X,Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude,grounded) then
   local face=p.Character:FindFirstChild("PaddleFace")
   local center=(face and face.Position or r.Position)+r.CFrame.LookVector*Rules.HIT_RANGE*reach*0.25
   -- Union with the normal sphere: only the forward intercept volume is added.
   distance=math.min(distance,(ball.p-center).Magnitude)
  end
  local inReach=Rules.contactInFront(ball.p,r.CFrame) and (distance<=Rules.HIT_RANGE*reach+extension or overhead)
  local valid=ball.live and ball.last~=d.side and ball.p.Z*d.side>=-1 and inReach
  if automatic and not valid then return false end
  local clean=valid and (distance<=Rules.PERFECT_RANGE*reach*(Augments.has(d.augments,"carbonFiber") and 1.15 or 1)+extension or overhead) and (perfect(now,d) or kitchenLobWindow(p,d,r,overhead))
  if guided or feint or deceptive or shield then clean=valid end
  if ball.spin and not fire and not guided and not feint and not deceptive and not shield then
   clean=clean and (perfect(now,d) and distance<=Rules.PERFECT_RANGE*reach*(Augments.has(d.augments,"carbonFiber") and 1.15 or 1)+extension or overhead)
  end
  if not Rules.hitReady(now,d.lastSwing,clean) then return false end
  d.lastSwing=clean and now or now+Rules.HIT_COOLDOWN
  p.Character:SetAttribute("HitReadyAt",workspace:GetServerTimeNow()+(clean and 0 or Rules.HIT_COOLDOWN))
  if not valid then
   feedback:FireAllClients({userId=p.UserId,backhand=backhand,soft=softRequested and Rules.softShot(r.Position,d.side) or nil},"swing")
   if not automatic then tell(p,"Miss!","miss") end
   return
  end
  if ball.shots==0 and receiverId and p.UserId~=receiverId then
   point(-d.side,"Wrong receiver: the diagonal player must return the serve"); return false
  end
  local kitchenFault=Rules.kitchenHitFault(r.Position,ball.p,d.side,now<d.diveUntil)
   or (d.kitchenTouched and p.Character.Humanoid.FloorMaterial==Enum.Material.Air)
  local fault=Rules.returnFault(ball.bounces,ball.shots,kitchenFault)
  if fault then point(-d.side,fault); return false end
  if ball.deadly then point(ball.last,"Unreturnable paddle strike"); return true end
  if ball.bounces==0 and ball.soft=="dink" and ball.hitter then
   local prior=Players:GetPlayerByUserId(ball.hitter)
   if prior and users[prior] then Augments.dink(users[prior].augmentRally,false) end
  end
  local humanoid=p.Character:FindFirstChildOfClass("Humanoid")
  local erne=Augments.has(d.augments,"erne") and ball.bounces==0 and ball.shots>=2
   and math.abs(r.Position.X)>Rules.HALF_WIDTH+1 and math.abs(r.Position.Z)<=Rules.KITCHEN+4
   and humanoid and humanoid.FloorMaterial==Enum.Material.Air and not d.kitchenTouched
  if erne then clean=true end
  if ball.bounces==0 then d.volleyPending=true; d.volleySettled=0 end
  local _,timeToBounce=landing()
  local quality=Rules.shotQuality(clean,timeToBounce,now-ball.bounceAt)
  local soft=(guided or feint or deceptive) and "drop" or softRequested and clean and Rules.softShot(r.Position,d.side) or nil
  if soft or (shotKind=="Slice" and clean) then quality="perfect" end
  if shotKind=="Lob" and not feint and not guided and not deceptive then quality="lob"; soft=nil end
  local serveReturn=ball.shots==0
  ball.shots+=1
  local slam=clean and overhead and not soft and shotKind~="Lob" and shotKind~="Slice" and not shield
  local restored=clean and ball.speed<1
  if clean then ball.perfects+=1 end
  local charged=charge>0 and not soft and not softRequested and not slam
  if charged then
   d.chargeShotAt=now+1
   p.Character:SetAttribute("ChargedShotReadyAt",workspace:GetServerTimeNow()+1)
  end
  local accelerationMessage
  ball.speed,accelerationMessage=Augments.acceleration(d.augments,d.augmentRally,ball.speed,clean,slam,charged,Rules.returnSpeed)
  local calculated=serveReturn and not diving and not soft and shotKind~="Lob" and shotKind~="Slice" and Augments.has(d.augments,"calculatedReturn")
  if calculated then ball.speed*=0.8 end
  local target,momentum=facingTarget(ball.p,r,d.side,soft and (soft=="dink" and 7 or 10) or (slam and 35 or 27))
  if charged and not clean then
   local timingError=math.min(timeToBounce,now-ball.bounceAt)
   local severity=math.clamp((timingError-0.23)/0.42,0.25,1)
   target=Rules.chargeTarget(ball.p,target,charge,severity,math.random()*2-1,math.random())
  end
  if guided or feint or deceptive or shield then
   local opponent=occupant(-d.side)
   local opponentRoot=opponent and rootOf(opponent)
   local aimX=opponentRoot and opponentRoot.Position.X or botX
   -- Guidance reduces lateral aim error by 40%; feints and shields use a safe center target.
   local x=guided and aimX+(target.X-aimX)*0.6 or target.X
   target=Vector3.new(math.clamp(x,-17,17),FLOOR,-d.side*(shield and 27 or 7))
  end
  local multiplier=1
  if not soft and not slam and not shield and quality~="lob" and shotKind~="Lob" and shotKind~="Slice" and Augments.has(d.augments,"dinkSpecialist") then
   multiplier=Augments.drive(d.augmentRally,r.Position.Z*d.side>=Rules.BASELINE-4)
  end
  local dinkBoost=multiplier>1
  if Comeback.active(comeback,d.side) then multiplier*=Comeback.HIT end
  if soft~="dink" then Augments.dink(d.augmentRally,false) end
  local deadly=erne or (fire and slam and not d.augmentRally.overchargeUsed)
  if erne then multiplier*=3 end
  if fire and slam then d.augmentRally.overchargeUsed=true end
  if feint then
   for _,opponent in ipairs(teamPlayers(-d.side)) do
    local enemy=users[opponent]; local enemyRoot=rootOf(opponent)
    if enemyRoot and enemyRoot.AssemblyLinearVelocity.Z*enemy.side>1 then enemy.augmentRally.stunUntil=now+1 end
   end
   if courtMode=="Practice" and botTarget.Z<botZ then botStunUntil=now+1 end
   tell(p,"BAIT AND SWITCH!","perfect")
  end
  local rhythm=clean and ball.shots+1>10 and Augments.has(d.augments,"rhythmMaster")
  local afterimage=Augments.has(d.augments,"afterimage") and now-d.augmentRally.diveStarted<=1
  if offensive then
   for _,opponent in ipairs(teamPlayers(-d.side)) do
    local data=users[opponent]
    if Augments.onFire(data.augments,data.augmentRally,ball.shots+1) then offensive=false; break end
   end
   if offensive then quality="perfect" end
  end
  local triggered={thirdShot=guided,baitSwitch=feint,deflector=shield,erne=erne,overcharge=fire and slam,
   deceptiveDrop=deceptive,offensiveDive=offensive,apexPredator=heavy,rhythmMaster=rhythm,afterimage=afterimage,
   calculatedReturn=calculated,sliceDice=shotKind=="Slice",dinkSpecialist=dinkBoost,
   perfectVision=clean,carbonFiber=clean,phantom=backhand,
   momentumShift=accelerationMessage=="MOMENTUM SHIFT! +15%",terminalVelocity=accelerationMessage=="TERMINAL VELOCITY! +8%"}
  for id,active in pairs(triggered) do if active then activateAugment(p,id) end end
  local powered=clean and not soft and now<d.powerUntil
  d.powerUntil=0
  ball.last=d.side; lastHitter[d.side]=p
  launch(ball.p,Vector3.new(target.X,FLOOR,target.Z),powered,quality=="lob",slam,momentum,soft,quality=="net",charged and charge or 0,{userId=p.UserId,clean=clean,
   reflectedSpeed=shield and incomingSpeed*2 or calculated and incomingSpeed*0.8 or nil,
   offensive=offensive,heavy=heavy,deceptive=deceptive,afterimage=afterimage,
   uncapped=Augments.has(d.augments,"terminalVelocity") and not shield and not calculated,speedMultiplier=multiplier,spin=(guided or offensive) and "topspin" or shotKind=="Slice" and "slice" or nil,
   sliceBoost=Augments.has(d.augments,"sliceDice"),atp=Augments.has(d.augments,"atpAssassin"),deadly=deadly})

  feedback:FireAllClients({userId=p.UserId,backhand=backhand,slam=slam or deceptive,hidePaddle=rhythm,contact=ball.p,direction=ball.v.Unit,charge=charge,soft=not deceptive and (soft or (softRequested and Rules.softShot(r.Position,d.side) or nil)) or nil},"swing")
  local message=restored and (slam and "SLAM!  SPEED RESET TO 1.00x" or "PERFECT!  SPEED RESET TO 1.00x")
   or (slam and "SLAM!  +10%" or (clean and "PERFECT!  +5%" or "LOB RETURN  /  -5%"))
  if charged and clean then message="CHARGED RETURN!  +7%"
  elseif charged and quality~="net" then message="MISTIMED CHARGE  /  WIDE RETURN" end
  if soft then message=soft=="dink" and "PERFECT DINK!" or "PERFECT DROP!"
  elseif quality=="net" then message="BAD TIMING  /  LOW CONTACT" end
  if accelerationMessage then message=accelerationMessage end
  feedback:FireAllClients({userId=p.UserId,text=message,tone=clean and "good" or (quality=="net" or charged) and "bad" or "neutral"},"playerText")
  d.diveUntil=0
  return true
end
input.OnServerEvent:Connect(function(p,action,moveIntent)
 local d=users[p]
 if not d or d.side==0 or type(action)~="string" then return end
 local now=os.clock()
 if action=="DiveHeld" then d.diveHeld=moveIntent==true; return end
 if now<d.augmentRally.stunUntil and action=="Dive" then return end
 if now<introUntil or draft or draftDue then return end
 -- Release/cancel must survive the flood gate, even for a very quick tap.
 if action=="ChargeCancel" then d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end; return end
 local releasedCharge
 if action=="ChargeRelease" then
  if not d.chargeAt then return end
  releasedCharge=Rules.chargeAmount(d.chargeAt,now); d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  if ball.live and releasedCharge>0 and now<(d.chargeShotAt or 0) then releasedCharge=0; d.chargeCooldownBlocked=true end
 end
 -- Remote flood protection does not impose a gameplay cooldown on perfect returns.
 if releasedCharge==nil and action~="ServeTimingStop" and action~="ServeChargeStart" and now-d.lastInput<0.015 then return end
 d.lastInput=now
 local r,h=rootOf(p)
 if not r or not h or h.Health<=0 then return end
 if action=="ServeChargeStart" then
  if not serveReady or not serveDeadline or workspace:GetServerTimeNow()>=serveDeadline then return end
  if p.UserId~=serverId and not (servingSide==-1 and not occupant(-1) and p.UserId==receiverId) then return end
  d.serveChargeAt=d.serveChargeAt or workspace:GetServerTimeNow()
  p.Character:SetAttribute("ShotChargeAt",d.serveChargeAt)
 elseif action=="ChargeStart" then
  if not ball.live and not (serveReady and (p.UserId==serverId or (servingSide==-1 and not occupant(-1) and p.UserId==receiverId))) then return end
  d.chargeAt=d.chargeAt or now
  p.Character:SetAttribute("ShotChargeAt",workspace:GetServerTimeNow())
 elseif action=="ChargeRelease" then
  if ball.live then
   local hit=tryReturn(p,d,r,now,false,false,releasedCharge)
   if hit and d.chargeCooldownBlocked then tell(p,"CHARGED SHOT RECHARGING  /  NORMAL HIT","info") end
   d.chargeCooldownBlocked=nil
  else serve(p,d,r,h) end
 elseif action=="ServeTimingStop" or action=="Serve" or (action=="Swing" and not ball.live) then
  serve(p,d,r,h)
 elseif action=="Dive" then
  if not Rules.canDive(d.stamina/(d.augmentRally.lava and 2 or 1),d.diveAt,now) then return end
  d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  local cooldown=Rules.DIVE_COOLDOWN*(1-((d.augments and d.augments.dive) or 0))
  d.stamina=math.max(0,d.stamina-Rules.DIVE_STAMINA_COST*(d.augmentRally.lava and 2 or 1)); d.diveAt=now+cooldown
  d.staminaRecoveryAt=now+Rules.STAMINA_RECOVERY_DELAY
  local moveTime,poseTime=Augments.diveDuration(d.augments)
  d.diveUntil=now+moveTime; d.divePoseUntil=now+poseTime; d.diveCharacter=p.Character
  d.augmentRally.diveStarted=now
  activateAugment(p,"quickRecovery",poseTime); activateAugment(p,"afterimage",2)
  local delta=ball.live and ball.p-r.Position or Vector3.zero
  if typeof(moveIntent)~="Vector3" or moveIntent.X~=moveIntent.X or moveIntent.Z~=moveIntent.Z then
   moveIntent=h.MoveDirection
  end
  moveIntent=Vector3.new(math.clamp(moveIntent.X,-1,1),0,math.clamp(moveIntent.Z,-1,1))
  local direction=Rules.diveDirection(moveIntent,r.CFrame.LookVector,delta)
  feedback:FireAllClients({userId=p.UserId,direction=direction.Unit,moveTime=moveTime,poseTime=poseTime,afterimage=Augments.has(d.augments,"afterimage"),diveReadyAt=workspace:GetServerTimeNow()+cooldown},"diveMotion")
  tell(p,"DIVE","dive")
 elseif action=="Power" then
  if courtVariant=="Augmented" then return end
  if now<d.powerAt then return end
  d.powerAt=now+10; d.powerUntil=now+5
  tell(p,"POWER SHOT ARMED  /  5s","power")
 elseif action=="Slow" then
  if courtVariant=="Augmented" then return end
  if now<d.slowAt then return end
  d.slowAt=now+12
  local opponents=teamPlayers(-d.side)
  if #opponents==0 then botSlowUntil=now+2.5 end
  for _,opponent in ipairs(opponents) do
   users[opponent].slowUntil=now+2.5; tell(opponent,"SLOWED  /  2.5s","slow")
  end
  tell(p,"OPPONENT SLOWED","power")
 elseif action=="Lob" or action=="Slice" then
  if ball.live then tryReturn(p,d,r,now,false,false,0,action) end
  d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
 elseif action=="Swing" or action=="SoftShot" then
  d.serveChargeAt=nil; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  if ball.live then tryReturn(p,d,r,now,false,action=="SoftShot") end
 end
end)
local accumulator,broadcast=0,0
RunService.Heartbeat:Connect(function(dt)
 local now=os.clock()
 updateDraft(now)
 local pickupParticipants={}
 for player,data in pairs(users) do
  if data.side~=0 then table.insert(pickupParticipants,{player=player,side=data.side}) end
 end
 powerups:update(now,(now<introUntil or courtVariant=="Augmented") and {} or pickupParticipants)
 for p,d in pairs(users) do
  local recovered=Rules.recoverStamina(d.stamina,d.staminaRecoveryAt or 0,now,dt)
  d.stamina=math.min(100,d.stamina+(recovered-d.stamina)*(1+((d.augments and d.augments.regen) or 0)))
  local r,h=rootOf(p)
  if r and h and h.Health>0 then
   local effect=d.augmentRally
   local camper=false
   if ball.live and d.side~=0 and Augments.has(d.augments,"kitchenCamper") then
    camper=Augments.camp(effect,r.Position.Z*d.side,r.Position.X,Rules.KITCHEN,Rules.BASELINE)
   end
   local baseline=Augments.has(d.augments,"baselineSentinel") and math.abs(r.Position.Z*d.side-Rules.BASELINE)<=4 and math.abs(r.Position.X)<=Rules.HALF_WIDTH
   p:SetAttribute("BaselineSentinelActive",baseline and d.side~=0)
   -- Client biases only the lateral input. Recover the original input ratio for speed.
   local move=h.MoveDirection
   local original=Vector3.new(baseline and move.X/1.15 or move.X,0,move.Z)
   local lateral=original.Magnitude>0.01 and original.Unit.X or 0
   local movement=(1+(d.augments.speed or 0)+(d.augmentMatch.speedWins or 0)*0.05)*Augments.lateralScale(d.augments,r.Position.Z*d.side,r.Position.X,lateral)*(camper and 1.15 or 1)*(now<effect.burstUntil and 1.75 or 1)*(Comeback.active(comeback,d.side) and Comeback.MOVE or 1)
   local stunned=now<effect.stunUntil
   h.WalkSpeed=(stunned or d.mode=="Spectate" or (d.side~=0 and (now<introUntil or draft~=nil))) and 0 or (now<d.slowUntil and SLOWED_SPEED or WALK_SPEED)*movement
   p:SetAttribute("AugmentStunned",stunned)
   if stunned then r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0) end
   local face=p.Character:FindFirstChild("PaddleFace")
   local fire=ball.live and Augments.onFire(d.augments,effect,ball.shots+1)
   if face then
    face.Material=fire and Enum.Material.Neon or Enum.Material.SmoothPlastic
    face.Color=fire and Color3.fromRGB(255,115,25) or Color3.fromRGB(31,193,180)
   end
   local grounded=h.FloorMaterial~=Enum.Material.Air
   local active={kitchenCamper=camper,baselineSentinel=baseline and math.abs(move.X)>0.1,
    kitchenWarden=Augments.warden(d.augments,r.Position.Z*d.side,r.Position.X,Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude,grounded),
    overcharge=fire,dinkSpecialist=effect.driveReady==true,momentumShift=effect.perfectChain>=3}
   for id,on in pairs(active) do
    if ball.live and on and not (d.augmentActive and d.augmentActive[id]) then activateAugment(p,id) end
   end
   d.augmentActive=active
   local inKitchen=Rules.inKitchen(r.Position,1)
   if grounded then d.kitchenTouched=inKitchen end
   if ball.live and d.side~=0 and grounded and math.abs(r.Position.X)<=Rules.HALF_WIDTH+1
    and math.abs(r.Position.Z*d.side-Rules.KITCHEN)<=1 then
    for _,opponent in ipairs(teamPlayers(-d.side)) do
     if Augments.has(users[opponent].augments,"lava") then
      if not effect.lava then activateAugment(opponent,"lava",1.5) end
      effect.lava=true
     end
    end
   end
   if grounded and inKitchen and d.volleyPending and ball.live then
    point(-d.side,"Kitchen volley fault")
   end
   if d.volleyPending and ball.live then
    if grounded and Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude<2 then
     d.volleySettled=(d.volleySettled or 0)+dt
     if d.volleySettled>0.15 then d.volleyPending=false end
    else d.volleySettled=0 end
   end
   if d.side~=0 then
    local x,z
    if now<d.diveUntil then
     x=r.Position.X
     z=r.Position.Z
    else
     x=r.Position.X
     z=d.side*math.max(r.Position.Z*d.side,2.5)
    end
    if math.abs(x-r.Position.X)>0.1 or math.abs(z-r.Position.Z)>0.1 or r.Position.Y<178 then
     r.CFrame=CFrame.new(x,math.max(r.Position.Y,184),z)*r.CFrame.Rotation
    end
   end
  end
 end
 local hasBot=courtMode=="Practice" and occupant(1)~=nil and occupant(-1)==nil
 for _,p in ipairs(bot:GetChildren()) do if p:IsA("BasePart") then p.Transparency=hasBot and 0 or 1 end end
 tag.Enabled=hasBot
 if not draft and not draftDue and not ball.live and not serveReady and now>=nextServe and occupant(1) then prepareServe() end
 if serveReady and serveDeadline and workspace:GetServerTimeNow()>=serveDeadline then
  local server=serverId and Players:GetPlayerByUserId(serverId)
  for player,data in pairs(users) do
   data.serveChargeAt=nil; data.chargeAt=nil
   if player.Character then player.Character:SetAttribute("ShotChargeAt",nil) end
  end
  serveReady=false; serveDeadline=nil
  ball.last=servingSide; ball.shots=0; ball.speed=Rules.servePower(0)
  if server then
   lastHitter[servingSide]=server
   ball.live=true
   feedback:FireClient(server,{grade="SERVE TIMEOUT",offset=1,accuracy=0},"serveTiming")
   point(-servingSide,"Serve timeout")
  else
   -- The practice partner has no human input; only bot serves are automatic.
   ball.speed=Rules.servePower(1)
   local from=Vector3.new(serveX,184,servingSide*46)
   launch(from,Rules.serveTarget(nil,servingSide,serveX),false,false,false,0,nil,false,0,{maxVelocity=Rules.MAX_SERVE_VELOCITY})
   banner="BOT SERVE / LET IT BOUNCE"
  end
 end
 if ball.live then
  accumulator+=math.min(dt,0.1)
  while accumulator>=1/120 and ball.live do
   local step=1/120
   accumulator-=step
   -- Check throughout the dive at the same fixed rate as ball physics.
   for p,d in pairs(users) do
    if d.side~=0 and d.diveUntil and now<d.diveUntil and p.Character==d.diveCharacter then
     local r,h=rootOf(p)
     if r and h and h.Health>0 then tryReturn(p,d,r,now,true) end
    end
   end
   for p,d in pairs(users) do
    if ball.live and d.side~=0 and d.side~=ball.last and Augments.has(d.augments,"deflector")
     and not ball.lob and not ball.soft and ball.shots>=2 then
     local r,h=rootOf(p)
     if r and h and h.Health>0 and math.abs(ball.p.Y-r.Position.Y)<=1.5
      and Vector3.new(ball.p.X-r.Position.X,0,ball.p.Z-r.Position.Z).Magnitude<=2.5
      and (r.Position-ball.p):Dot(ball.v)>0 then
      tryReturn(p,d,r,now,true,false,0,"Deflect")
     end
    end
   end
   if not ball.live then break end
   local previous=ball.p
   ball.p,ball.v,ball.g=Rules.advanceFlight(ball.p,ball.v,ball.flightGravity or GRAVITY,step,ball.lob,ball.bounces>0,ball.offensive,ball.last)
   if previous.Z*ball.p.Z<=0 and math.abs(ball.p.X)<21 and ball.p.Y<184.65 then
    point(-ball.last,"Net")
   elseif ball.p.Y<=FLOOR then
    local fraction=math.clamp((previous.Y-FLOOR)/math.max(0.0001,previous.Y-ball.p.Y),0,1)
    local impact=previous:Lerp(ball.p,fraction)
    feedback:FireAllClients({position=impact,speed=ball.speed,onCourt=math.abs(impact.X)<=20.09 and math.abs(impact.Z)<=40.09},"ballBounce")
    if ball.bounces==0 and (math.abs(impact.X)>20.09 or math.abs(impact.Z)>40.09) then
     ball.outLanding=Vector3.new(impact.X,FLOOR,impact.Z)
    end
    if ball.bounces>=1 then
     point(ball.last,"Double bounce")
    elseif ball.shots==0 and not Rules.serveLandingValid(ball.p,servingSide,serveX) then
     point(-servingSide,"Serve fault: land in the diagonal service court")
    elseif math.abs(ball.p.X)>20.09 or math.abs(ball.p.Z)>40.09 then
     point(-ball.last,"Out")
    elseif ball.p.Z*ball.last>0 then
     point(-ball.last,"Short return")
    else
     local hitter=ball.hitter and Players:GetPlayerByUserId(ball.hitter)
     local hitterData=hitter and users[hitter]
     if hitterData then
      if Augments.has(hitterData.augments,"dinkSpecialist") and ball.soft=="dink" then
       Augments.dink(hitterData.augmentRally,Rules.inKitchen(impact))
       if Rules.inKitchen(impact) then activateAugment(hitter,"dinkSpecialist") end
      end
      if ball.atp then
       activateAugment(hitter,"atpAssassin",1.2)
       for _,opponent in ipairs(teamPlayers(-ball.last)) do
        local enemy=users[opponent]
        enemy.stamina=math.max(0,enemy.stamina-30*(enemy.augmentRally.lava and 2 or 1))
        enemy.staminaRecoveryAt=now+Rules.STAMINA_RECOVERY_DELAY
       end
       tell(hitter,"ATP CRITICAL! / -30% STAMINA","perfect")
      end
     end
     ball.bounces+=1
     if ball.bounces>=2 then point(ball.last,"Double bounce")
     else
      ball.p=Vector3.new(ball.p.X,FLOOR,ball.p.Z)
      ball.v=Rules.bounceVelocity(ball.v,ball.lob)
      local spinScale=Augments.bounceScale(ball.spin,ball.sliceBoost)
      -- An ignited receiver negates incoming spin before the bounce.
      for _,receiver in ipairs(teamPlayers(-ball.last)) do
       local data=users[receiver]
       if Augments.onFire(data.augments,data.augmentRally,ball.shots+1) then spinScale=1 end
      end
      ball.v=Vector3.new(ball.v.X,ball.v.Y*spinScale,ball.v.Z)
      ball.g=(ball.flightGravity or GRAVITY)*(ball.lob and Rules.LOB_GRAVITY_SCALE or 1)*(ball.offensive and 1.8 or 1)
      ball.bounceAt=now
      ball.bouncePoint=ball.p
     end
    end
   elseif ball.p.Y<170 then
    point(ball.bounces>0 and ball.last or -ball.last,"Rally over")
   end
  end
 else accumulator=0 end
 botMoving=false
 if hasBot and ball.live then
  if botShotId~=ball.shotId then
   botShotId=ball.shotId
   botReactAt=now+botRandom:NextNumber(0.22,0.42)
   botThinkAt=botReactAt; botAttempted=false
   botError=Vector3.new(botRandom:NextNumber(-3,3),0,botRandom:NextNumber(-2,2))
  end
  -- Read the flight periodically instead of following its exact landing every frame.
  if now>=botThinkAt then
   botThinkAt=now+0.18
   if ball.last==1 then
    local predicted=landing()
    botTarget=Vector3.new(math.clamp(predicted.X+botError.X,-30,30),0,
     math.clamp(predicted.Z-3+botError.Z,-Rules.BACK_LIMIT,-2.5))
   else botTarget=Vector3.new(0,0,-28) end
  end
  local delta=botTarget-Vector3.new(botX,0,botZ)
  local move=math.min(delta.Magnitude,math.min(dt,0.1)*(now<botSlowUntil and SLOWED_SPEED or WALK_SPEED)*(Comeback.active(comeback,-1) and Comeback.MOVE or 1))
  if now<botStunUntil then move=0 end
  botMoving=move>0.01
  botStride+=move*0.65
  if delta.Magnitude>0.01 then botX+=delta.Unit.X*move; botZ+=delta.Unit.Z*move end
  local rootPosition=Vector3.new(botX,184,botZ)
  local rootFrame=CFrame.lookAt(rootPosition,rootPosition+Vector3.new(0,0,1))
  local center=Vector3.new(botX,184.5,botZ+1)
  local distance=(ball.p-center).Magnitude
  if ball.last==1 and now>=botReactAt and now>=botSwingAt and not botAttempted
   and ball.p.Z< -2 and distance<6.5*(Comeback.active(comeback,-1) and Comeback.HIT or 1) and Rules.contactInFront(ball.p,rootFrame)
   and ball.p.Y<188 and (ball.v.Y<0 or ball.bounces>0)
   and not Rules.returnFault(ball.bounces,ball.shots,Rules.kitchenHitFault(rootPosition,ball.p,-1,false)) then
   -- One attempt per incoming shot: a whiff cannot be retried on the next frame.
   botAttempted=true; botSwingAt=now+0.28
   local pressure=math.clamp((ball.speed-1)*0.15+(distance/6.5)*0.08,0,0.18)
   if ball.deadly then
    point(ball.last,"Unreturnable paddle strike")
   elseif botRandom:NextNumber()>=0.10+pressure then
    if ball.bounces==0 and ball.soft=="dink" and ball.hitter then
     local prior=Players:GetPlayerByUserId(ball.hitter)
     if prior and users[prior] then Augments.dink(users[prior].augmentRally,false) end
    end
    local clean=perfect(now) and distance<=Rules.PERFECT_RANGE and botRandom:NextNumber()<0.55
    local _,timeToBounce=landing()
    local quality=Rules.shotQuality(clean,timeToBounce,now-ball.bounceAt)
    if clean then ball.perfects+=1 end
    ball.speed=Rules.returnSpeed(ball.speed,clean,false)
    ball.last=-1; ball.shots+=1
    local targetX=botRandom:NextNumber(-15,15)
    local targetZ=botRandom:NextNumber(20,34)
    if botRandom:NextNumber()<0.07+pressure*0.3 then
     targetX=(targetX<0 and -1 or 1)*botRandom:NextNumber(21,25)
    end
    launch(ball.p,Vector3.new(targetX,FLOOR,targetZ),false,quality=="lob",false,0,nil,quality=="net",0,{clean=clean,speedMultiplier=Comeback.active(comeback,-1) and Comeback.HIT or 1})
    feedback:FireAllClients({userId=0,text=clean and "PERFECT!" or "LOB RETURN",tone=clean and "good" or "neutral"},"playerText")
   end
  end
 end
 botBody.Position=Vector3.new(botX,184.2,botZ)
 botHead.Position=Vector3.new(botX,186.3,botZ)
 botPaddle.CFrame=CFrame.new(botX-1.8,184.4,botZ+1)*CFrame.Angles(0,0,0.2)
 for i,p in ipairs(botLegs) do
  local stride=botMoving and math.sin(botStride)*(i==1 and 1 or -1) or 0
  p.CFrame=CFrame.new(botX+(i==1 and -0.6 or 0.6),182.4,botZ+stride*0.45)*CFrame.Angles(stride*0.4,0,0)
 end
 if serveReady then
  local server=serverId and Players:GetPlayerByUserId(serverId)
  ball.p=Rules.heldBallPosition(server and server.Character or (hasBot and bot)) or ball.p
 end
 broadcast+=dt
 if broadcast>=0.05 then
  broadcast=0
  local target,t=landing()
  if ball.live and now-ball.bounceAt<=0.28 and ball.bouncePoint then
   target=ball.bouncePoint; t=0
  end
  for p,d in pairs(users) do
   local hidden,glitch,heavy=Augments.tracking(d.side~=0 and d.side~=ball.last,ball.live,now,ball.trackingHiddenUntil,ball.trackingGlitchUntil,ball.heavy,ball.p.Z*ball.last>0)
   local viewPosition,viewVelocity=ball.p,ball.v
   if heavy and ball.launchPosition then
    local scale=math.max(1,ball.speed*(ball.shotMultiplier or 1))
    local age=(now-ball.launchedAt)/scale
    viewPosition,viewVelocity=Rules.advanceFlight(ball.launchPosition,ball.launchVelocity,ball.flightGravity or GRAVITY,age,ball.lob,false,ball.offensive,ball.last)
    viewVelocity/=scale
   end
   local activeEffects={}
   for id,on in pairs(d.augmentActive or {}) do if ball.live and on and Augments.has(d.augments,id) then activeEffects[id]=true end end
   for id,untilTime in pairs(d.augmentPulses or {}) do if now<untilTime then activeEffects[id]=true end end
   if ball.live then
    if (d.augmentMatch.reachStacks or 0)>0 then activeEffects.vampiricReach=true end
    if (d.augmentMatch.speedWins or 0)>0 then activeEffects.terminalVelocity=true end
    if Augments.has(d.augments,"lava") then
     for _,opponent in ipairs(teamPlayers(-d.side)) do if users[opponent].augmentRally.lava then activeEffects.lava=true end end
    end
   end
   for _,id in ipairs({"carbonFiber","perfectVision","phantom"}) do if ball.live and Augments.has(d.augments,id) then activeEffects[id]=true end end
   local auraTier=0
   for _,card in ipairs(Augments.catalog) do if activeEffects[card.id] then auraTier=math.max(auraTier,card.tier) end end
   if ball.live and d.side~=0 then
    for _,stat in ipairs({"speed","regen","reach","dive"}) do if (d.augments[stat] or 0)>0 then auraTier=math.max(auraTier,1) end end
   end
   p:SetAttribute("ActiveAugmentTier",ball.live and d.side~=0 and auraTier or 0)
   p:SetAttribute("ComebackBoost",Comeback.active(comeback,d.side))
   state:FireClient(p,{
    comeback=Comeback.active(comeback,d.side),
    augmentEffects=activeEffects,augmentProgress={tension=d.augmentRally.tension,perfectChain=d.augmentRally.perfectChain,
     reachStacks=d.augmentMatch.reachStacks or 0,speedWins=d.augmentMatch.speedWins or 0,secondServeUsed=d.augmentMatch.secondServeUsed==true},
    matchIntro=d.side~=0 and now<introUntil and matchIntro or nil,
    trackingHidden=hidden,trackingGlitch=glitch,heavy=heavy,visualRate=heavy and 1/math.max(1,ball.speed*(ball.shotMultiplier or 1)) or 1,
    offensive=ball.offensive,decoyLanding=glitch and target+Vector3.new(target.X>0 and -6 or 6,0,3) or nil,
    outLanding=ball.outLanding,p=viewPosition,v=viewVelocity,g=ball.g,flightGravity=ball.flightGravity or GRAVITY,lob=ball.lob,live=ball.live,landing=target,eta=t,
    slammable=ball.live and ball.slamLob,shotId=ball.shotId,slamReady=slamReady(p,d,now),
    green=ball.live and perfect(now,d),last=ball.last,bounces=ball.bounces,
    perfects=ball.perfects,speed=ball.speed*(ball.live and ball.shotMultiplier or 1),score=score,banner=banner,
    serveReady=serveReady,servingSide=servingSide,serveX=serveX,serverId=serverId,receiverId=receiverId,serverNumber=rotation.number,
    serverName=(serverId and Players:GetPlayerByUserId(serverId) and Players:GetPlayerByUserId(serverId).DisplayName) or "Practice Partner",
    serveDeadline=serveDeadline,serveRemaining=serveDeadline and math.max(0,serveDeadline-workspace:GetServerTimeNow()) or 0,
    canServe=serveReady and (p.UserId==serverId or (hasBot and servingSide==-1 and p.UserId==receiverId)),
    mustBounce=ball.live and ball.shots<2 and ball.bounces==0,
    augmentStatus=ball.live and (Augments.onFire(d.augments,d.augmentRally,ball.shots+1) and "ON FIRE"
     or now<d.augmentRally.stunUntil and "STUNNED" or d.augmentRally.lava and "KITCHEN IS LAVA / 2x DRAIN"
     or d.augmentRally.perfectChain>=3 and Augments.has(d.augments,"momentumShift") and "MOMENTUM SHIFT READY"
     or d.augmentRally.driveReady and "TENSION READY / BASELINE DRIVE" or "") or "",
    side=d.side,bot=hasBot,stamina=d.stamina,dive=math.max(0,d.diveAt-now),
    diveReadyAt=workspace:GetServerTimeNow()+math.max(0,d.diveAt-now),
    homeName=teamName(1),awayName=teamName(-1),
    power=math.max(0,d.powerAt-now),slow=math.max(0,d.slowAt-now),
    armed=math.max(0,d.powerUntil-now),slowed=math.max(0,d.slowUntil-now)
   })
  end
 end
end)
