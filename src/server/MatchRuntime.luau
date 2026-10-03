-- One isolated ball, score, serve rotation and player roster per court.
local Players=game:GetService("Players")
local Runtime={}
function Runtime.new(match,court,network,viewers,finish)
local offset=match.offset
local state=network.State
local feedback={}
local function payload(message)
 if type(message)~="table" then return message end
 local copy=table.clone(message)
 copy.matchId=match.id
 for _,key in ipairs({"position","contact"}) do
  if typeof(copy[key])=="Vector3" then copy[key]+=offset end
 end
 return copy
end
function feedback:FireAllClients(message,kind)
 for _,player in ipairs(viewers(match.id)) do network.Feedback:FireClient(player,payload(message),kind) end
end
function feedback:FireClient(player,message,kind) network.Feedback:FireClient(player,payload(message),kind) end
local RulesForPosition=require(script.Parent:WaitForChild("MatchRules"))
local function heldBallPosition(character)
 local position=RulesForPosition.heldBallPosition(character)
 return position and position-offset
end
local FLOOR,GRAVITY,BASE_SPEED=181.7,45,56
local WALK_SPEED,SLOWED_SPEED=22,10
local STREAK_CAP=10
local MAX_STAMINA,DIVE_COST,STAMINA_REGEN=100,35,22
local crowd=require(script.Parent:WaitForChild("CrowdReactions")).new()
local rulesModule=script.Parent:WaitForChild("MatchRules")
local Rules=require(rulesModule)
local BodyBounce=require(script.Parent:WaitForChild("BodyBounce"))
local BotDifficulty=require(script.Parent:WaitForChild("BotDifficulty"))
local botSettings=BotDifficulty.Normal
local users={}
local matchActive=false
local matchEnding=false
local rotation=require(script.Parent:WaitForChild("ServeRotation")).new()
local score=rotation.score
local lastHitter={}
local ball={p=Vector3.new(0,187,-28),v=Vector3.zero,g=GRAVITY,live=false,last=-1,bounces=0,perfects=0,speed=1,bounceAt=-100}
local nextServe=0
local servingSide,serveReady,serveX=1,false,10
local SERVE_TIMEOUT=15
local serveDeadline=0
local serveZoneCenter=0.95
local serverId,receiverId
ball.shots=0
local banner="Welcome to Skyline Club"
local botSlowUntil=0
local botX,botZ=0,-28
local botRandom=Random.new()
local botShotId,botReactAt,botThinkAt,botSwingAt=nil,0,0,0
local botTarget=Vector3.new(0,0,-28)
local botError=Vector3.zero
local botAttempted=false
local botStride,botMoving=0,false
local world=court
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
local function teamName(side)
 local names={}
 for _,p in ipairs(teamPlayers(side)) do table.insert(names,p.DisplayName) end
 return #names>0 and table.concat(names," + ") or (side==-1 and "Practice Partner" or "Waiting for players")
end
local function syncServing()
 servingSide=rotation.side; serverId=rotation.serverId; receiverId=rotation:receiverId(); serveX=rotation:serveX()
end
local function setMissImmune(p,d,immune)
 d.missImmune=immune
 if p.Character then p.Character:SetAttribute("MissImmune",immune) end
end
local function setStreak(p,d,count,react)
 if react and count==0 and crowd:streakEnded(d.perfectStreak or 0) then
  feedback:FireAllClients({},"crowdGasp")
 end
 d.perfectStreak=count
 if count==0 then setMissImmune(p,d,false) end
 if p.Character then p.Character:SetAttribute("PerfectStreak",count) end
end
local function rosterChanged()
 crowd:reset()
 local home,away={},{}
 for _,p in ipairs(teamPlayers(1)) do table.insert(home,p.UserId) end
 for _,p in ipairs(teamPlayers(-1)) do table.insert(away,p.UserId) end
 if match.bot then away={0} end
 rotation:setTeams(home,away)
 if #home==0 and #away==0 then rotation:reset(); score=rotation.score end
 syncServing()
 ball.live=false; ball.v=Vector3.zero; ball.speed=1; ball.perfects=0
 ball.outLanding=nil; serveReady=false; nextServe=os.clock()+1
 for p,d in pairs(users) do
  setStreak(p,d,0)
  d.diveUntil=0; d.volleyPending=false; d.chargeAt=nil
  if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
 end
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
local function lobCrossesSlamZone(from,velocity,gravity,duration)
 -- Classify the whole shot at launch, independent of a receiver's current position.
 -- A blue arc advertises an overhead opportunity, not a guaranteed legal hit.
 for step=0,120 do
  local t=duration*step/120
  local position=from+velocity*t-Vector3.new(0,0.5*gravity*t*t,0)
  local side=-ball.last
  local root=Vector3.new(math.clamp(position.X,-Rules.HALF_WIDTH,Rules.HALF_WIDTH),184,side*(Rules.KITCHEN+2))
  local headTop,armLength=187,4
  if Rules.overheadReach(position,root,headTop+Rules.SLAM_MIN_HEIGHT,headTop+armLength+Rules.SLAM_EXTRA_HEIGHT)
   and (position-(root+Vector3.new(0,0,-side*2))).Magnitude<=Rules.SLAM_RANGE then return true end
 end
 return false
end
local function launch(from,target,boost,lob,slam,momentum,soft,mishit,charge,contact)
 ball.slam=slam==true
 ball.undercharged=contact and contact.undercharged==true
 ball.deadBounce=nil
 local speedScale=(slam and Rules.slamSpeedScale(ball.speed) or ball.speed)*(boost and 1.22 or 1)*(1+0.12*(momentum or 0))
 if not slam and not soft then speedScale*=1+0.22*(charge or 0) end
 -- Speed changes flight time and launch velocity; downward gravity stays constant.
 if soft then speedScale*=0.65 end
 local distance=(Vector3.new(target.X,0,target.Z)-Vector3.new(from.X,0,from.Z)).Magnitude
 local gravity=GRAVITY
 if contact and (contact.serveQuality=="great" or contact.serveQuality=="perfect") then
  -- Scale time and gravity together so the faster serve keeps its legal arc.
  local multiplier=contact.serveQuality=="perfect" and Rules.SERVE_PERFECT_SPEED or Rules.SERVE_GREAT_SPEED
  speedScale*=multiplier
  gravity*=multiplier^2
 end
 local duration=slam and math.max(0.12,math.min(distance/(BASE_SPEED*1.8),math.sqrt(2*math.max(0.1,from.Y-FLOOR)/gravity)*0.75)) or math.max(0.7,distance/BASE_SPEED)
 if lob then duration=math.max(duration*1.35,1.5) end
 duration=duration/math.max(0.1,speedScale)
 if contact and contact.minDuration then duration=math.max(duration,contact.minDuration) end
 local vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
 local crossing=(0-from.Z)/(target.Z-from.Z)
 if not mishit and crossing>0 and crossing<1 then
  local tc=duration*crossing
  local netY=from.Y+vy*tc-0.5*gravity*tc*tc
  if netY<185.2 then
   duration=math.sqrt(math.max(0.01,2*(185.2-from.Y-(FLOOR-from.Y)*crossing)/(gravity*crossing*(1-crossing))))
   vy=(FLOOR-from.Y+0.5*gravity*duration*duration)/duration
  end
 end
 if contact and contact.serveQuality=="perfect" then
  -- Compare the same flight with a slam, including its net clearance correction.
  local slamDuration=math.max(0.12,math.min(distance/(BASE_SPEED*1.8),math.sqrt(2*math.max(0.1,from.Y-FLOOR)/GRAVITY)*0.75))
  slamDuration/=Rules.slamSpeedScale(ball.speed)*(1+0.12*(momentum or 0))
  if crossing>0 and crossing<1 then
   local slamVy=(FLOOR-from.Y+0.5*GRAVITY*slamDuration^2)/slamDuration
   local tc=slamDuration*crossing
   if from.Y+slamVy*tc-0.5*GRAVITY*tc^2<185.2 then
    slamDuration=math.sqrt(math.max(0.01,2*(185.2-from.Y-(FLOOR-from.Y)*crossing)/(GRAVITY*crossing*(1-crossing))))
   end
  end
  local perfectDuration=slamDuration/0.92
  local originalDuration=duration
  duration=perfectDuration
  if crossing>0 and crossing<1 then
   -- Keep flight time (and forward speed), but solve a low arc just above the net.
   local netHeight=185.15
   gravity=math.max(0.01,2*(netHeight-from.Y-(FLOOR-from.Y)*crossing)/(duration^2*crossing*(1-crossing)))
  else gravity*=(originalDuration/perfectDuration)^2 end
  vy=(FLOOR-from.Y+0.5*gravity*duration^2)/duration
 end
 if contact and contact.serveQuality=="great" and crossing>0 and crossing<1 then
  -- Flatten great serves without changing their flight time or forward speed.
  local netHeight=185.35
  gravity=math.max(0.01,2*(netHeight-from.Y-(FLOOR-from.Y)*crossing)/(duration^2*crossing*(1-crossing)))
  vy=(FLOOR-from.Y+0.5*gravity*duration^2)/duration
 end
 if mishit then
  -- Keep horizontal aim, but send the ball below net height without clearance assist.
  if crossing>0 and crossing<1 then
   local tc=duration*crossing
   vy=(183.3-from.Y+0.5*gravity*tc*tc)/tc
  else vy=math.min(vy,-3) end
 end
 ball.lob=lob==true
 ball.p=from
 ball.g=gravity
 ball.v=Vector3.new((target.X-from.X)/duration,vy,(target.Z-from.Z)/duration)
 ball.shotId=(ball.shotId or 0)+1
 ball.slamLob=ball.lob and lobCrossesSlamZone(from,ball.v,ball.g,duration)
 ball.bounces=0; ball.bounceAt=-100; ball.live=true
 -- All viewers receive the same accepted contact, including practice-partner hits.
 contact=contact or {}
 for p,d in pairs(users) do
  if d.side~=ball.last then setMissImmune(p,d,false)
  elseif p.UserId==contact.userId then setMissImmune(p,d,contact.clean==true) end
 end
 contact.position=from; contact.direction=ball.v.Unit; contact.speed=ball.speed
 contact.slam=slam==true; contact.powered=boost==true; contact.charge=charge or 0; contact.soft=soft
 feedback:FireAllClients(contact,"ballHit")
 if crowd:shot(ball.speed,ball.lob) then feedback:FireAllClients({},"crowdGasp") end
end
-- Only unbounced slams cause body saves; the slow lob remains playable.
local function bodyReturn(previous,hasBot)
 if not ball.slam or ball.bounces~=0 then return end
 local earliest,hitPlayer,hitSide
 local function check(character,side,player)
  if not character or side~=-ball.last then return end
  for _,part in ipairs(character:GetChildren()) do
   if part:IsA("BasePart") and part.Name~="HumanoidRootPart" and not part.Name:find("Paddle") then
    local fraction=BodyBounce.contact(previous,ball.p,part.CFrame-offset,part.Size)
    if fraction and (not earliest or fraction<earliest) then
     earliest=fraction; hitPlayer=player; hitSide=side
    end
   end
  end
 end
 for p,d in pairs(users) do
  local _,h=rootOf(p)
  if d.side~=0 and h and h.Health>0 then check(p.Character,d.side,p) end
 end
 if hasBot then check(bot,-1,nil) end
 if not earliest then return end
 if hitPlayer then setStreak(hitPlayer,users[hitPlayer],0,true) end
 local position=previous:Lerp(ball.p,earliest)
 local target,speed,duration=BodyBounce.shot(position,ball.v,hitSide,ball.speed,FLOOR)
 ball.speed=speed; ball.last=hitSide; ball.shots+=1
 lastHitter[hitSide]=hitPlayer
 launch(position,target,false,true,false,0,nil,false,0,{userId=hitPlayer and hitPlayer.UserId or 0,minDuration=duration})
 if hitPlayer then tell(hitPlayer,"BODY BOUNCE / SLOW LOB","info") end
end
local function point(winner,reason)
 if not ball.live then return end
 ball.live=false; ball.v=Vector3.zero; ball.perfects=0; ball.speed=1
 for p,d in pairs(users) do setStreak(p,d,0,true) end
 crowd:reset()
 local index=winner==1 and 1 or 2
 local outcome=rotation:award(winner)
 local scored=outcome=="point"
 syncServing()
 banner="TEAM "..(servingSide==1 and "1" or "2")..(scored and " POINT / " or outcome=="secondServer" and " SECOND SERVER / " or " SIDE OUT / ")..reason
 serveReady=false
 for p,d in pairs(users) do d.diveUntil=0; d.volleyPending=false; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end end
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
  ["Body hit"]="Body Hit!",
 }
 feedback:FireAllClients({title=scored and (scorerName.." Scored for Team "..index.."!") or outcome=="secondServer" and "Second Server!" or "Side Out!",fault=faultNames[reason] or (reason.."!")},"rallyResult")
 if scored and score[index]>=11 and math.abs(score[1]-score[2])>=2 then
  banner="TEAM "..index.." WINS!  /  Returning to lobby"
  feedback:FireAllClients(banner,"point")
  nextServe=math.huge
  matchEnding=true
  task.delay(5,function()
   if matchActive then finish(match.id,"Team "..index.." wins! Queue again when ready.") end
  end)
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
 if not r or not h or not matchActive then return end
 setStreak(p,d,0)
 h.WalkSpeed=WALK_SPEED; h.UseJumpPower=true; h.JumpPower=38
 local position=d.side==0 and Vector3.new(112,185,20) or Vector3.new(0,185,d.side*28)
 c:PivotTo(CFrame.lookAt(position,Vector3.new(0,185,0))+offset)
 if not c:FindFirstChild("PaddleFace") then paddle(c) end
 d.kitchenTouched=false; d.volleyPending=false; d.diveUntil=0; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
end
local function start()
  matchActive=true; matchEnding=false
  botSettings=BotDifficulty[match.difficulty] or BotDifficulty.Normal
  botSlowUntil=0
  tagText.Text=match.bot and (string.upper(match.difficulty).." PRACTICE BOT") or "PRACTICE PARTNER"
  ball.live=false; ball.v=Vector3.zero; ball.outLanding=nil; ball.resetScore=false
  for _,team in ipairs({{ids=match.home,side=1},{ids=match.away,side=-1}}) do
   for slot,id in ipairs(team.ids) do
    if id==0 then continue end
    local p=Players:GetPlayerByUserId(id)
    local d=p and users[p]
    assert(d,"Queued player missing")
    d.side=team.side; d.slot=slot; d.stamina=MAX_STAMINA
    d.diveAt=0; d.powerAt=0; d.slowAt=0; d.powerUntil=0; d.slowUntil=0; d.lastSwing=0
    p:SetAttribute("CourtSide",team.side)
    if p.Character then
     p.Character:SetAttribute("HitReadyAt",nil); p.Character:SetAttribute("ChargedShotReadyAt",nil)
     task.spawn(spawnCharacter,p,p.Character)
    end
   end
  end
  rotation:setTeams(match.home,match.away); rotation:reset(); score=rotation.score
  rosterChanged()
end
local function prepareServe()
 if not matchActive or matchEnding then return end
 for _,id in ipairs(match.members) do
  local p=Players:GetPlayerByUserId(id)
  local r,h
  if p then r,h=rootOf(p) end
  if not r or not h or h.Health<=0 then return end
 end
 if ball.resetScore then rotation:reset(); score=rotation.score; ball.resetScore=false end
 syncServing()
 if not occupant(servingSide) and servingSide==1 then return end
 table.clear(lastHitter)
 for p,d in pairs(users) do
  local r,h=rootOf(p)
  if d.side~=0 and r and h and h.Health>0 then
   local primary=p.UserId==(d.side==servingSide and serverId or receiverId)
   local position=Rules.startPosition(d.side,servingSide,serveX,primary)
   p.Character:PivotTo(CFrame.lookAt(position,Vector3.new(position.X,185,0))+offset)
   r.AssemblyLinearVelocity=Vector3.zero
   d.diveUntil=0; d.volleyPending=false; d.kitchenTouched=false; d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  end
 end
 if servingSide==-1 and not occupant(-1) then botX=serveX; botZ=-46
 else botX=-serveX; botZ=-46 end
 botShotId=nil; botAttempted=false; botSwingAt=0
 botTarget=Vector3.new(botX,0,botZ)
 ball.outLanding=nil
 ball.p=Vector3.new(serveX,184,servingSide*46)
 ball.v=Vector3.zero; ball.speed=1; ball.perfects=0; ball.shots=0
 ball.bounces=0; ball.bounceAt=-100; ball.last=servingSide
 serveReady=true
 serveZoneCenter=Rules.serveZoneCenter(math.random())
 serveDeadline=workspace:GetServerTimeNow()+SERVE_TIMEOUT
 banner="TEAM "..(servingSide==1 and "1" or "2").." / SERVER "..rotation.number.." TO SERVE"
end
local function facingTarget(from,r,side,depth)
 local direction,momentum=Rules.shotAim((r.CFrame-offset),r.AssemblyLinearVelocity,from)
 depth+=momentum*4
 -- Facing plus a bounded movement offset; out shots remain possible.
 local distance=math.abs(-side*depth-from.Z)/math.max(0.25,math.abs(direction.Z))
 return from+direction*math.clamp(distance,12,110),momentum
end
local function serve(p,d,r,h,charge,automatic,serveHeld)
 if not serveReady then return end
 if not automatic and os.clock()<d.lastSwing then return end
 charge=charge or 0
 local botServing=servingSide==-1 and not occupant(-1)
 if p.UserId~=serverId and not (botServing and p.UserId==receiverId) then
  tell(p,"WAIT FOR THE DESIGNATED SERVER","info"); return
 end
 local from=Vector3.new(serveX,184,servingSide*46)
 if botServing then from=heldBallPosition(bot) or from end
 if not botServing then
  if automatic then
   -- Timeout serves start legally even if the server walked away, jumped, or is respawning.
   if r and h and h.Health>0 then
    local position=Vector3.new(serveX,185,servingSide*46)
    p.Character:PivotTo(CFrame.lookAt(position,Vector3.new(-serveX,185,-servingSide*28))+offset)
    r.AssemblyLinearVelocity=Vector3.zero
   end
  elseif not Rules.servePositionValid((r.Position-offset),d.side,serveX,h.FloorMaterial~=Enum.Material.Air) then
   tell(p,"Foot Fault! Serve from behind the baseline on the marked side.","fault"); return
  end
  if not automatic then from=heldBallPosition(p.Character) or Vector3.new((r.Position-offset).X,184,(r.Position-offset).Z) end
 end
 if not botServing then lastHitter[servingSide]=p end
 serveReady=false; ball.last=servingSide; ball.shots=0
 serveDeadline=0; d.chargeAt=nil
 if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
 local target,momentum
 if automatic then
  serveHeld=Rules.randomServeHold(math.random(1,5),math.random(),serveZoneCenter)
  charge=Rules.chargeAmount(0,serveHeld)
 elseif botServing then serveHeld=Rules.randomServeHold(3,0.5,serveZoneCenter) end
 charge=Rules.serveMeterPosition(serveHeld)/Rules.SERVE_METER_TIME
 local serveQuality,depth=Rules.serveCharge(serveHeld,serveZoneCenter)
 if botServing or automatic then target=Vector3.new(-serveX,FLOOR,-servingSide*depth)
 else
  target,momentum=facingTarget(from,r,d.side,depth)
  -- Charge controls depth; movement cannot rescue an early release or shorten an overcharge.
  target=Vector3.new(target.X,FLOOR,-servingSide*depth)
 end
 d.lastSwing=os.clock()+Rules.HIT_COOLDOWN
 if p.Character then p.Character:SetAttribute("HitReadyAt",workspace:GetServerTimeNow()+Rules.HIT_COOLDOWN) end
 launch(from,Vector3.new(target.X,FLOOR,target.Z),false,false,false,momentum,nil,serveQuality=="net",charge,{userId=not botServing and p.UserId or nil,serveQuality=serveQuality,undercharged=serveQuality=="short" or serveQuality=="net"})
 if not botServing then
  feedback:FireAllClients({userId=p.UserId,backhand=false,contact=from,direction=ball.v.Unit,charge=charge},"swing")
  if not automatic then
   local message=serveQuality=="perfect" and "PERFECT SERVE!" or serveQuality=="great" and "GREAT SERVE!" or serveQuality=="good" and "GOOD SERVE!" or serveQuality=="out" and "OVERCHARGED SERVE!" or "UNDERPOWERED SERVE!"
   tell(p,message,(serveQuality=="good" or serveQuality=="great" or serveQuality=="perfect") and "perfect" or "fault")
  end
 end
 banner="SERVE  /  LET IT BOUNCE"
end
local function automaticServe()
 local id=serverId==0 and receiverId or serverId
 local p=id and Players:GetPlayerByUserId(id)
 local d=p and users[p]
 if not d then return end
 local r,h=rootOf(p)
 serve(p,d,r,h,0,true)
end
local function overheadStatus(p,r)
  local face=p.Character:FindFirstChild("PaddleFace")
  local center=face and (face.Position-offset) or (r.Position-offset)
  local distance=(ball.p-center).Magnitude
  local minY,maxY=Rules.slamBounds(p.Character,r)
  local overhead=Rules.contactInFront(ball.p,(r.CFrame-offset)) and distance<=Rules.SLAM_RANGE and Rules.overheadReach(ball.p,(r.Position-offset),minY,maxY)
 return distance,overhead
end
local function kitchenLobWindow(p,d,r,overhead)
 return Rules.kitchenLobWindow(ball.lob,overhead,(r.Position-offset),d.side)
end
local function slamReady(p,d,now)
 local r,h=rootOf(p)
 if not r or not h or h.Health<=0 or d.side==0 then return false end
 if not ball.live or ball.last==d.side or ball.p.Z*d.side< -1 then return false end
 if ball.shots==0 and receiverId and p.UserId~=receiverId then return false end
 if Rules.returnFault(ball.bounces,ball.shots,Rules.kitchenHitFault((r.Position-offset),ball.p,d.side,now<d.diveUntil)) then return false end
 local _,overhead=overheadStatus(p,r)
 return overhead and (perfect(now) or kitchenLobWindow(p,d,r,overhead))
end
local function tryReturn(p,d,r,now,automatic,softRequested,charge)
  if d.missImmune and ball.live and ball.last==d.side then return false end
  charge=charge or 0
  local distance,overhead=overheadStatus(p,r)
  local inReach=Rules.contactInFront(ball.p,(r.CFrame-offset)) and (distance<=Rules.HIT_RANGE or overhead)
  local valid=ball.live and ball.last~=d.side and ball.p.Z*d.side>=-1 and inReach
  if automatic and not valid then return false end
  local clean=valid and (distance<=Rules.PERFECT_RANGE or overhead) and (perfect(now) or kitchenLobWindow(p,d,r,overhead))
  if not Rules.hitReady(now,d.lastSwing,clean) then return false end
  d.lastSwing=clean and now or now+Rules.HIT_COOLDOWN
  p.Character:SetAttribute("HitReadyAt",workspace:GetServerTimeNow()+(clean and 0 or Rules.HIT_COOLDOWN))
  local backhand=(r.CFrame-offset):PointToObjectSpace(ball.p).X<0
  if not valid then
   setStreak(p,d,0,true)
   feedback:FireAllClients({userId=p.UserId,backhand=backhand,soft=softRequested and Rules.softShot((r.Position-offset),d.side) or nil},"swing")
   if not automatic then tell(p,"Miss!","miss") end
   return
  end
  if ball.shots==0 and receiverId and p.UserId~=receiverId then
   point(-d.side,"Wrong receiver: the diagonal player must return the serve"); return false
  end
  local kitchenFault=Rules.kitchenHitFault((r.Position-offset),ball.p,d.side,now<d.diveUntil)
  local fault=Rules.returnFault(ball.bounces,ball.shots,kitchenFault)
  if fault then point(-d.side,fault); return false end
  if ball.bounces==0 then d.volleyPending=true; d.volleySettled=0 end
  local _,timeToBounce=landing()
  local quality=Rules.shotQuality(clean,timeToBounce,now-ball.bounceAt)
  local soft=softRequested and clean and Rules.softShot((r.Position-offset),d.side) or nil
  ball.shots+=1
  local slam=clean and overhead and not soft
  local restored=clean and ball.speed<1
  if clean then ball.perfects+=1 end
  setStreak(p,d,clean and (d.perfectStreak or 0)+1 or 0,true)
  local charged=charge>0 and not softRequested and not slam
  if charged then
   d.chargeShotAt=now+1
   p.Character:SetAttribute("ChargedShotReadyAt",workspace:GetServerTimeNow()+1)
  end
  ball.speed=Rules.returnSpeed(ball.speed,clean,slam,charged)
  if not soft then ball.speed+=math.min(d.perfectStreak,STREAK_CAP)*0.03 end
  local target,momentum=facingTarget(ball.p,r,d.side,soft and (soft=="dink" and 7 or 10) or (slam and 35 or 27))
  if charged and not clean then
   local timingError=math.min(timeToBounce,now-ball.bounceAt)
   local severity=math.clamp((timingError-0.23)/0.42,0.25,1)
   target=Rules.chargeTarget(ball.p,target,charge,severity,math.random()*2-1,math.random())
  end
  local powered=clean and not soft and now<d.powerUntil
  d.powerUntil=0
  ball.last=d.side; lastHitter[d.side]=p
  launch(ball.p,Vector3.new(target.X,FLOOR,target.Z),powered,quality=="lob",slam,momentum,soft,quality=="net",charged and charge or 0,{userId=p.UserId,clean=clean})
  feedback:FireAllClients({userId=p.UserId,backhand=backhand,slam=slam,contact=ball.p,direction=ball.v.Unit,charge=charge,soft=soft or (softRequested and Rules.softShot((r.Position-offset),d.side) or nil)},"swing")
  local message=restored and (slam and "SLAM!  SPEED RESET TO 1.00x" or "PERFECT!  SPEED RESET TO 1.00x")
   or (slam and "SLAM!  +10%" or (clean and "PERFECT!  +5%" or "LOB RETURN  /  -5%"))
  if charged and clean then message="CHARGED RETURN!  +7%"
  elseif charged and quality~="net" then message="MISTIMED CHARGE  /  WIDE RETURN" end
  if soft then message=soft=="dink" and "PERFECT DINK!" or "PERFECT DROP!"
  elseif quality=="net" then message="BAD TIMING  /  LOW CONTACT" end
  if clean then message..="  /  STREAK "..d.perfectStreak end
  feedback:FireAllClients({userId=p.UserId,text=message,tone=clean and "good" or (quality=="net" or charged) and "bad" or "neutral"},"playerText")
  d.diveUntil=0
  return true
end
local function handleInput(p,action,moveIntent)
 local d=users[p]
 if not d or d.side==0 or not matchActive or matchEnding or type(action)~="string" then return end
 local now=os.clock()
 -- Release/cancel must survive the flood gate, even for a very quick tap.
 if action=="ChargeCancel" then d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end; return end
 local releasedCharge,serveHeld
 if action=="ChargeRelease" then
  if not d.chargeAt then return end
  serveHeld=now-d.chargeAt
  releasedCharge=Rules.chargeAmount(d.chargeAt,now); d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  if ball.live and releasedCharge>0 and now<(d.chargeShotAt or 0) then releasedCharge=0; d.chargeCooldownBlocked=true end
 end
 -- Remote flood protection does not impose a gameplay cooldown on perfect returns.
 if releasedCharge==nil and now-d.lastInput<0.015 then return end
 d.lastInput=now
 local r,h=rootOf(p)
 if not r or not h or h.Health<=0 then return end
 if action=="ChargeStart" then
  d.chargeAt=d.chargeAt or now
  p.Character:SetAttribute("ShotChargeAt",workspace:GetServerTimeNow())
 elseif action=="ChargeRelease" then
  if ball.live then
   local hit=tryReturn(p,d,r,now,false,false,releasedCharge)
   if hit and d.chargeCooldownBlocked then tell(p,"CHARGED SHOT RECHARGING  /  NORMAL HIT","info") end
   d.chargeCooldownBlocked=nil
  else serve(p,d,r,h,releasedCharge,false,serveHeld) end
 elseif action=="Serve" or (action=="Swing" and not ball.live) then
  if servingSide==-1 and not occupant(-1) and p.UserId==receiverId then
   serve(p,d,r,h)
  else tell(p,"HOLD LEFT CLICK / RELEASE IN GREEN TO SERVE","info") end
 elseif action=="Dive" then
  d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  if now<d.diveAt or d.stamina<DIVE_COST then return end
  d.stamina-=DIVE_COST; d.diveAt=now+1.1
  d.diveUntil=now+0.48; d.diveCharacter=p.Character
  local delta=ball.live and ball.p-(r.Position-offset) or Vector3.zero
  if typeof(moveIntent)~="Vector3" or moveIntent.X~=moveIntent.X or moveIntent.Z~=moveIntent.Z then
   moveIntent=h.MoveDirection
  end
  moveIntent=Vector3.new(math.clamp(moveIntent.X,-1,1),0,math.clamp(moveIntent.Z,-1,1))
  local direction=Rules.diveDirection(moveIntent,(r.CFrame-offset).LookVector,delta)
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
 elseif action=="Swing" or action=="SoftShot" then
  d.chargeAt=nil; if p.Character then p.Character:SetAttribute("ShotChargeAt",nil) end
  if ball.live then tryReturn(p,d,r,now,false,action=="SoftShot") end
 end
end
local accumulator,broadcast=0,0
local function step(dt)
 local now=os.clock()
 for p,d in pairs(users) do
  d.stamina=math.min(MAX_STAMINA,d.stamina+dt*STAMINA_REGEN)
  local r,h=rootOf(p)
  if r and h and h.Health>0 then
   h.WalkSpeed=now<d.slowUntil and SLOWED_SPEED or WALK_SPEED+math.min(d.perfectStreak or 0,STREAK_CAP)*0.8
   local grounded=h.FloorMaterial~=Enum.Material.Air
   local inKitchen=Rules.inKitchen((r.Position-offset),1)
   if grounded then d.kitchenTouched=inKitchen end
   if (r.Position-offset).Y<20 then
    -- Falling clear of the smaller, unguarded roof resets the player into the match.
    h.Health=0
   else
    if d.volleyPending and ball.live then
     if grounded and Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z).Magnitude<2 then
      d.volleySettled=(d.volleySettled or 0)+dt
      if d.volleySettled>0.15 then d.volleyPending=false end
     else d.volleySettled=0 end
    end
    local x,z
    if now<d.diveUntil then
     x=math.clamp((r.Position-offset).X,-60,60)
     z=math.clamp((r.Position-offset).Z,-82,82)
    else
     x=math.clamp((r.Position-offset).X,-60,60)
     z=d.side*math.clamp((r.Position-offset).Z*d.side,2.5,82)
    end
    if math.abs(x-(r.Position-offset).X)>0.1 or math.abs(z-(r.Position-offset).Z)>0.1 then
     r.CFrame=CFrame.new(x,(r.Position-offset).Y,z)*(r.CFrame-offset).Rotation+offset
    end
   end
  end
 end
 local hasBot=matchActive and match.bot==true
 for _,p in ipairs(bot:GetChildren()) do if p:IsA("BasePart") then p.Transparency=hasBot and 0 or 1 end end
 tag.Enabled=hasBot
 if matchActive and not matchEnding and not ball.live and not serveReady and now>=nextServe and occupant(1) then prepareServe() end
 if matchActive and not matchEnding and serveReady and workspace:GetServerTimeNow()>=serveDeadline then automaticServe() end
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
   if not ball.live then break end
   local previous=ball.p
   ball.p+=ball.v*step+Vector3.new(0,-0.5*ball.g*step*step,0)
   ball.v+=Vector3.new(0,-ball.g*step,0)
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
     local rebound=ball.undercharged and Rules.bounceVelocity(ball.v.Y,true) or nil
     point(-servingSide,"Serve fault: land in the diagonal service court")
     if rebound then ball.deadBounce={position=impact,started=now,velocity=rebound}; ball.p=impact; ball.g=GRAVITY; ball.v=Vector3.new(0,rebound,0) end
    elseif math.abs(ball.p.X)>20.09 or math.abs(ball.p.Z)>40.09 then
     point(-ball.last,"Out")
    elseif ball.p.Z*ball.last>0 then
     point(-ball.last,"Short return")
    else
     ball.bounces+=1
     if ball.bounces>=2 then point(ball.last,"Double bounce")
     else
      ball.p=Vector3.new(ball.p.X,FLOOR,ball.p.Z)
      -- Damp steep lob impacts and keep rebounds between 2.2 and 4.4 studs high.
      ball.v=Vector3.new(ball.v.X,Rules.bounceVelocity(ball.v.Y,ball.undercharged),ball.v.Z)
      ball.bounceAt=now
      ball.bouncePoint=ball.p
     end
    end
   elseif ball.p.Y<170 then
    point(ball.bounces>0 and ball.last or -ball.last,"Rally over")
   else
    bodyReturn(previous,hasBot)
   end
  end
 else
  accumulator=0
  if ball.deadBounce then
   local elapsed=now-ball.deadBounce.started
   local height=math.max(0,ball.deadBounce.velocity*elapsed-0.5*GRAVITY*elapsed^2)
   ball.p=ball.deadBounce.position+Vector3.new(0,height,0)
   ball.v=Vector3.new(0,ball.deadBounce.velocity-GRAVITY*elapsed,0)
   if elapsed>=2*ball.deadBounce.velocity/GRAVITY then ball.deadBounce=nil; ball.v=Vector3.zero end
  end
 end
 botMoving=false
 if hasBot and ball.live then
  if botShotId~=ball.shotId then
   botShotId=ball.shotId
   botReactAt=now+botRandom:NextNumber(botSettings.reactionMin,botSettings.reactionMax)
   botThinkAt=botReactAt; botAttempted=false
   botError=Vector3.new(botRandom:NextNumber(-botSettings.errorX,botSettings.errorX),0,botRandom:NextNumber(-botSettings.errorZ,botSettings.errorZ))
  end
  -- Read the flight periodically instead of following its exact landing every frame.
  if now>=botThinkAt then
   botThinkAt=now+botSettings.think
   if ball.last==1 then
    local predicted=landing()
    botTarget=Vector3.new(math.clamp(predicted.X+botError.X,-30,30),0,
     math.clamp(predicted.Z-3+botError.Z,-Rules.BACK_LIMIT,-2.5))
   else botTarget=Vector3.new(0,0,-28) end
  end
  local delta=botTarget-Vector3.new(botX,0,botZ)
  local move=math.min(delta.Magnitude,math.min(dt,0.1)*(now<botSlowUntil and SLOWED_SPEED or botSettings.speed))
  botMoving=move>0.01
  botStride+=move*0.65
  if delta.Magnitude>0.01 then botX+=delta.Unit.X*move; botZ+=delta.Unit.Z*move end
  local rootPosition=Vector3.new(botX,184,botZ)
  local rootFrame=CFrame.lookAt(rootPosition,rootPosition+Vector3.new(0,0,1))
  local center=Vector3.new(botX,184.5,botZ+1)
  local distance=(ball.p-center).Magnitude
  if ball.last==1 and now>=botReactAt and now>=botSwingAt and not botAttempted
   and ball.p.Z< -2 and distance<6.5 and Rules.contactInFront(ball.p,rootFrame)
   and ball.p.Y<188 and (ball.v.Y<0 or ball.bounces>0)
   and not Rules.returnFault(ball.bounces,ball.shots,Rules.kitchenHitFault(rootPosition,ball.p,-1,false)) then
   -- One attempt per incoming shot: a whiff cannot be retried on the next frame.
   botAttempted=true; botSwingAt=now+0.28
   local pressure=math.clamp((ball.speed-1)*0.15+(distance/6.5)*0.08,0,0.18)*botSettings.pressureScale
   if botRandom:NextNumber()>=botSettings.miss+pressure then
    local clean=perfect(now) and distance<=Rules.PERFECT_RANGE and botRandom:NextNumber()<botSettings.perfect
    local _,timeToBounce=landing()
    local quality=Rules.shotQuality(clean,timeToBounce,now-ball.bounceAt)
    if clean then ball.perfects+=1 end
    ball.speed=Rules.returnSpeed(ball.speed,clean,false)
    ball.last=-1; ball.shots+=1
    local targetX=botRandom:NextNumber(-15,15)
    local targetZ=botRandom:NextNumber(20,34)
    if botRandom:NextNumber()<botSettings.out+pressure*0.3 then
     targetX=(targetX<0 and -1 or 1)*botRandom:NextNumber(21,25)
    end
    launch(ball.p,Vector3.new(targetX,FLOOR,targetZ),false,quality=="lob",false,0,nil,quality=="net",0,{clean=clean})
    feedback:FireAllClients({userId=0,text=clean and "PERFECT!" or "LOB RETURN",tone=clean and "good" or "neutral"},"playerText")
   end
  end
 end
 botBody.Position=Vector3.new(botX,184.2,botZ)+offset
 botHead.Position=Vector3.new(botX,186.3,botZ)+offset
 botPaddle.CFrame=CFrame.new(botX-1.8,184.4,botZ+1)*CFrame.Angles(0,0,0.2)+offset
 for i,p in ipairs(botLegs) do
  local stride=botMoving and math.sin(botStride)*(i==1 and 1 or -1) or 0
  p.CFrame=CFrame.new(botX+(i==1 and -0.6 or 0.6),182.4,botZ+stride*0.45)*CFrame.Angles(stride*0.4,0,0)+offset
 end
 if serveReady then
  local server=serverId and Players:GetPlayerByUserId(serverId)
  ball.p=heldBallPosition(server and server.Character or (hasBot and bot)) or ball.p
 end
 broadcast+=dt
 if broadcast>=0.05 then
  broadcast=0
  local target,t=landing()
  if ball.live and now-ball.bounceAt<=0.28 and ball.bouncePoint then
   target=ball.bouncePoint; t=0
  end
  for _,p in ipairs(viewers(match.id)) do
   local d=users[p] or {side=0,stamina=MAX_STAMINA,diveAt=0,powerAt=0,slowAt=0,powerUntil=0,slowUntil=0}
   state:FireClient(p,{
    matchId=match.id,offset=offset,courtName=court.Name,
    deadBounce=ball.deadBounce~=nil,outLanding=ball.outLanding and ball.outLanding+offset,p=ball.p+offset,v=ball.v,g=ball.g,live=ball.live,landing=target+offset,eta=t,
    slammable=ball.live and ball.slamLob,shotId=ball.shotId,slamReady=slamReady(p,d,now),
    green=ball.live and perfect(now),last=ball.last,bounces=ball.bounces,
    perfects=ball.perfects,speed=ball.speed,score=score,banner=banner,
    serveReady=serveReady,serveDeadline=serveReady and serveDeadline or nil,servingSide=servingSide,serveX=serveX,serverId=serverId,receiverId=receiverId,serverNumber=rotation.number,
    serverName=(serverId and Players:GetPlayerByUserId(serverId) and Players:GetPlayerByUserId(serverId).DisplayName) or "Practice Partner",
    serveZoneCenter=serveZoneCenter,
    canServe=serveReady and p.UserId==serverId,
    canRequestBotServe=serveReady and hasBot and serverId==0 and p.UserId==receiverId,
    mustBounce=ball.live and ball.shots<2 and ball.bounces==0,
    side=d.side,bot=hasBot,stamina=d.stamina,maxStamina=MAX_STAMINA,dive=math.max(0,d.diveAt-now,(DIVE_COST-d.stamina)/STAMINA_REGEN),
    homeName=teamName(1),awayName=teamName(-1),
    power=math.max(0,d.powerAt-now),slow=math.max(0,d.slowAt-now),
    armed=math.max(0,d.powerUntil-now),slowed=math.max(0,d.slowUntil-now)
   })
  end
 end
end
for _,id in ipairs(match.members) do
 local player=Players:GetPlayerByUserId(id)
 assert(player,"Queued player missing")
 users[player]={side=0,slot=0,joined=id,stamina=MAX_STAMINA,lastSwing=0,diveAt=0,powerAt=0,slowAt=0,powerUntil=0,slowUntil=0,lastInput=0}
end
start()
return {step=step,input=handleInput,spawn=spawnCharacter,focus=court:FindFirstChild("Playing surface"),score=function() return {score[1],score[2]} end,
 destroy=function()
  matchActive=false; crowd:reset()
  for p,d in pairs(users) do setStreak(p,d,0) end
  bot:Destroy(); court:Destroy()
 end}
end
return Runtime
