local MatchIntro=require(script.Parent:WaitForChild("MatchIntro"))
local MatchEnding={}
local mint=Color3.fromRGB(92,233,190)
local rose=Color3.fromRGB(245,150,178)

local function turn(pivot,x,z)
 return pivot*CFrame.Angles(x,0,z)*pivot:Inverse()
end

-- Each beat gives time, knee bend, forward lean, arm lift, and elbow curl.
local celebration={
 {0,0,0,0,0}, {0.42,0,0,0,0}, {0.70,0.40,0.20,0.20,0.18},
 {0.90,0.12,-0.06,1.12,0.85}, {1.12,0.23,-0.08,1.28,1.02},
 {1.43,0.36,0.15,0.68,0.64}, {1.70,0.05,0.01,0.95,0.86},
 {2.07,0.29,0.13,0.52,0.62}, {2.27,0.13,-0.04,1.14,0.91},
 {2.50,0.23,-0.06,1.26,1.04}, {2.79,0.33,0.13,0.62,0.68},
 {3.10,0.05,0,0.90,0.88}, {4.00,0.02,0,0.68,0.82},
 {5.30,0,0,0.34,0.52}, {7.40,0,0,0.18,0.30},
}

local function ease(t)
 t=math.clamp(t,0,1)
 return t*t*(3-2*t)
end

local function jumpHeight(elapsed,startTime,endTime)
 local progress=(elapsed-startTime)/(endTime-startTime)
 if progress<=0 or progress>=1 then return 0 end
 return 0.87*math.sin(math.pi*progress)^1.25
end

local function cheerPose(elapsed)
 for index=2,#celebration do
  local a,b=celebration[index-1],celebration[index]
  if elapsed<=b[1] then
   local t=ease((elapsed-a[1])/(b[1]-a[1]))
   return a[2]+(b[2]-a[2])*t,a[3]+(b[3]-a[3])*t,
    a[4]+(b[4]-a[4])*t,a[5]+(b[5]-a[5])*t
  end
 end
 return 0,0,0.18,0.30
end

local function prepare(actor)
 local rig=actor.model
 local groups={}
 local function pivot(part,attachmentName)
  local attachment=part:FindFirstChild(attachmentName)
  if attachment and attachment:IsA("Attachment") then
   return CFrame.new((actor.parts[part]*attachment.CFrame).Position)
  end
  -- R6 uses Motor6D joints without the R15 rig attachments.
  for _,joint in ipairs(rig:GetDescendants()) do
   if joint:IsA("Motor6D") and joint.Part1==part then
    return CFrame.new((actor.parts[part]*joint.C1).Position)
   end
  end
  return CFrame.new((actor.parts[part]*CFrame.new(0,part.Size.Y/2,0)).Position)
 end
 local function limb(side,first,second,extremity,jointName,lowerName,leg)
  local upper=rig:FindFirstChild(side..first) or rig:FindFirstChild(side.." "..(leg and "Leg" or "Arm"))
  if not upper or not actor.parts[upper] then return end
  local lower=rig:FindFirstChild(side..second)
  local group={
   root=pivot(upper,side..jointName.."RigAttachment"),
   joint=lower and pivot(lower,side..lowerName.."RigAttachment"),
   leg=leg,
  }
  groups[upper]={group=group}
  if lower then groups[lower]={group=group,lower=true} end
  local endPart=rig:FindFirstChild(side..extremity)
  if endPart then groups[endPart]={group=group,lower=true} end
  return group
 end
 actor.leftArm=limb("Left","UpperArm","LowerArm","Hand","Shoulder","Elbow",false)
 actor.rightArm=limb("Right","UpperArm","LowerArm","Hand","Shoulder","Elbow",false)
 actor.leftLeg=limb("Left","UpperLeg","LowerLeg","Foot","Hip","Knee",true)
 actor.rightLeg=limb("Right","UpperLeg","LowerLeg","Foot","Hip","Knee",true)
 for _,item in ipairs(rig:GetDescendants()) do
  if item:IsA("Weld") or item:IsA("WeldConstraint") then
   local a,b=item.Part0,item.Part1
   if actor.parts[a] and actor.parts[b] then
    if groups[a] and not groups[b] then groups[b]=groups[a]
    elseif groups[b] and not groups[a] then groups[a]=groups[b] end
   end
  end
 end
 for part in pairs(actor.armParts) do
  if not groups[part] and actor.rightArm then groups[part]={group=actor.rightArm,lower=true} end
 end
 actor.endingPelvis=rig:FindFirstChild("LowerTorso")
 local torso=rig:FindFirstChild("UpperTorso") or rig:FindFirstChild("Torso")
 actor.endingWaist=torso and actor.parts[torso] and pivot(torso,"WaistRigAttachment") or CFrame.identity
 actor.endingGroups=groups
end

local function support(pose,part)
 local half=part.Size/2
 return pose.Position.Y-math.abs(pose.RightVector.Y)*half.X-math.abs(pose.UpVector.Y)*half.Y-math.abs(pose.LookVector.Y)*half.Z
end

local function animateActor(actor,elapsed,won,index,spacing)
 if not actor.endingGroups then prepare(actor) end
 local lean,gaze,jump=0,0,0
 local transforms={}
 local function move(group,upperX,upperZ,lowerX)
  if not group then return end
  local upper=turn(group.root,upperX,upperZ)
  local lower=group.joint and upper*turn(group.joint,lowerX,0) or upper
  transforms[group]={upper=upper,lower=lower}
 end
 local handed=index==1 and 1 or -1
 if won then
  local bend,forward,lift,curl=cheerPose(elapsed)
  jump=jumpHeight(elapsed,0.87,1.43)+jumpHeight(elapsed,2.24,2.79)
  local pulse=math.sin(elapsed*5)*0.11*ease((elapsed-1.45)/0.35)*(1-ease((elapsed-4.0)/1.3))
  lean=forward
  gaze=-0.10*ease((elapsed-0.65)/0.3)
  local function cheer(arm,sign)
   if not arm then return end
   local extension=arm.joint and 0 or lift*0.25
   move(arm,lift+extension+sign*pulse*handed,sign*lift*0.09,curl)
  end
  cheer(actor.leftArm,-1)
  cheer(actor.rightArm,1)
  move(actor.leftLeg,bend*0.53,-bend*0.05,-bend)
  move(actor.rightLeg,bend*0.53,bend*0.05,-bend)
 else
  local drop=ease((elapsed-0.46)/1.2)
  local settle=ease((elapsed-1.5)/0.45)
  local breath=math.sin((elapsed-1.5)*4.2)*0.036*settle
  lean=0.32*drop+breath
  gaze=0.29*drop+breath
  move(actor.leftArm,(0.49+0.14*handed)*drop,-0.08*drop,1.57*drop)
  move(actor.rightArm,(0.49-0.14*handed)*drop,0.08*drop,1.57*drop)
  local function kneel(leg,roll)
   if not leg then return end
   move(leg,(leg.joint and 0.66 or -1.12)*drop,roll*drop,-2.19*drop)
  end
  kneel(actor.leftLeg,-0.025)
  kneel(actor.rightLeg,0.025)
 end
 local base=actor.pivot+Vector3.xAxis*spacing
 local upperBody=base*turn(actor.endingWaist,lean,0)
 local head=turn(actor.neck,gaze,0)
 local poses={}
 local lowest=math.huge
 for part,rest in pairs(actor.parts) do
  if part.Parent then
   local entry=actor.endingGroups[part]
   local pose=entry and transforms[entry.group]
   local localPose=pose and (entry.lower and pose.lower or pose.upper) or actor.headParts[part] and head or CFrame.identity
   local isLowerBody=part==actor.endingPelvis or (entry and entry.group.leg)
   local cf=(isLowerBody and base or upperBody)*localPose*rest
   poses[part]=cf
   if entry and entry.group.leg then lowest=math.min(lowest,support(cf,part)) end
  end
 end
 local lift=actor.floorY and lowest<math.huge and actor.floorY-lowest or 0
 for part,cf in pairs(poses) do part.CFrame=cf+Vector3.yAxis*(lift+jump) end
end

function MatchEnding.render(scene,elapsed,winner,dt)
 MatchIntro.updateScenes(scene)
 for index,shot in ipairs(scene.portraits) do
  local won=(index==1 and winner==1) or (index==2 and winner==-1)
  local twoPlayers=#shot.team>1
  local blend=1-math.exp(-7*(dt or 1/60))
  local separation=twoPlayers and 5.4 or 4.5
  if twoPlayers and shot.bounds then
   local width=0
   for _,bounds in pairs(shot.bounds) do width+=bounds.size.X/2 end
   separation=math.max(separation,width+1.1)
  end
  shot.endingSeparation=shot.endingSeparation and shot.endingSeparation+(separation-shot.endingSeparation)*blend or separation
  for slot,actor in pairs(shot.actors or {}) do
   local spacing=twoPlayers and (slot-1.5)*(shot.endingSeparation-4.5) or 0
   animateActor(actor,elapsed,won,slot,spacing)
  end
  if shot.baseCamera then
   -- Late avatars can change the fitted frame. Ease the correction without restarting the scene.
   shot.endingCamera=shot.endingCamera and shot.endingCamera:Lerp(shot.baseCamera,blend) or shot.baseCamera
   local pullback=(twoPlayers and 2.45 or 1.55)+math.max(0,shot.endingSeparation-5.4)
   local dolly=pullback+1.25*(1-ease(elapsed/2.8))
   shot.camera.CFrame=shot.endingCamera*CFrame.new(0,won and 0.24 or -0.38,dolly)
  end
 end
end

function MatchEnding.create(parent,data)
 -- A fixed viewpoint order keeps team placement and timing identical for all viewers.
 local root,title,scale,scene=MatchIntro.createScreen(parent,data,-1)
 root.Name="MatchEnding"
 local canvas=root.Canvas
 local leftWon=data.winner==1
 canvas.HomeHeading.Text=leftWon and "WINNERS" or "RUNNERS-UP"
 canvas.AwayHeading.Text=leftWon and "RUNNERS-UP" or "WINNERS"
 canvas.HomeHeading.TextColor3=leftWon and mint or rose
 canvas.AwayHeading.TextColor3=leftWon and rose or mint
 canvas.Round.Text="FINAL"
 canvas.VersusBadge.Visible=false
 canvas.MatchFormat.Visible=false
 local scoring=canvas:FindFirstChild("Figma_vsScoring")
 if scoring then scoring.Visible=false end
 title.Text="TEAM "..(leftWon and 1 or 2).." WINS!"
 title.TextColor3=mint
 local curtain=Instance.new("Frame",root)
 curtain.Name="Transition"; curtain.Size=UDim2.fromScale(1,1)
 curtain.BorderSizePixel=0; curtain.BackgroundColor3=Color3.fromRGB(8,11,27); curtain.ZIndex=15
 return root,scale,scene,curtain
end

function MatchEnding.start(player,network)
 local gui=Instance.new("ScreenGui")
 gui.Name="MatchEnding"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=80
 gui.Parent=player:WaitForChild("PlayerGui")
 local Players=game:GetService("Players")
 local data,root,scale,scene,curtain
 local fallback={}
 local function clear()
  if root then root:Destroy() end
  for _,avatar in pairs(fallback) do if avatar then avatar:Destroy() end end
  table.clear(fallback)
  data=nil; root=nil; scale=nil; scene=nil; curtain=nil
  player:SetAttribute("MatchEndingOpen",false)
 end
 player:GetAttributeChangedSignal("MatchSessionId"):Connect(clear)
 network:WaitForChild("State").OnClientEvent:Connect(function(state)
  if state.matchSessionId~=player:GetAttribute("MatchSessionId") then return end
  local ending=state.matchEnding
  if not ending or workspace:GetServerTimeNow()>=ending.endsAt then
   if data then clear() end
   return
  end
  if data and data.id==ending.id then return end
  clear()
  data=ending
  player:SetAttribute("MatchEndingOpen",true)
  root,scale,scene,curtain=MatchEnding.create(gui,ending)
  root.Visible=false
  scene.resolveAvatar=function(member)
   if member.bot then return end
   local id=member.userId
   if fallback[id]==nil then
    fallback[id]=false
    task.spawn(function()
     local ok,avatar=pcall(Players.CreateHumanoidModelFromUserIdAsync,Players,id)
     if not ok or not avatar then return end
     if data==ending then fallback[id]=avatar else avatar:Destroy() end
    end)
   end
   return fallback[id] or nil
  end
 end)
 game:GetService("RunService").RenderStepped:Connect(function(dt)
  if not data then return end
  local now=workspace:GetServerTimeNow()
  if now>=data.endsAt then clear(); return end
  root.Visible=now>=data.startsAt
  MatchIntro.resize(root,scale)
  MatchEnding.render(scene,math.max(0,now-data.startsAt),data.winner,dt)
  curtain.BackgroundTransparency=math.clamp(math.min(now-data.startsAt,data.endsAt-now)/0.35,0,1)
 end)
end

return MatchEnding
