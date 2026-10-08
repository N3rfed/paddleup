-- Presentation only; admission and match membership remain in the existing Session flow.
local Spectator={}
local active={}
local slots={}
local function snapshot(instance)
 if instance:IsA("BasePart") then
  return {Transparency=instance.Transparency,CanCollide=instance.CanCollide,CanTouch=instance.CanTouch,CanQuery=instance.CanQuery,CastShadow=instance.CastShadow,Anchored=instance.Anchored}
 elseif instance:IsA("Decal") then return {Transparency=instance.Transparency}
 elseif instance:IsA("ParticleEmitter") or instance:IsA("Trail") or instance:IsA("Beam") or instance:IsA("BillboardGui") then return {Enabled=instance.Enabled} end
end
function Spectator.leave(player)
 local state=active[player]; if not state then return end
 active[player]=nil; slots[state.slot]=nil
 state.connection:Disconnect()
 if state.track then state.track:Stop(0) end
 state.clone:Destroy()
 for instance,properties in pairs(state.saved) do
  if instance.Parent then for key,value in pairs(properties) do instance[key]=value end end
 end
 local h=state.character:FindFirstChildOfClass("Humanoid")
 if h then h.DisplayDistanceType=state.display; h.AutoRotate=state.rotate end
end
function Spectator.enter(player,character)
 Spectator.leave(player)
 local slot=1; while slots[slot] do slot+=1 end; slots[slot]=true
 local wasArchivable=character.Archivable; character.Archivable=true
 local clone=character:Clone(); character.Archivable=wasArchivable
 clone.Name=player.DisplayName.." (Spectator)"
 clone:SetAttribute("SpectatorUserId",player.UserId)
 for _,item in ipairs(clone:GetDescendants()) do
  if item:IsA("LuaSourceContainer") or item:IsA("Tool") or item.Name=="PaddleFace" or item.Name=="PaddleGrip" then item:Destroy() end
 end
 local h=clone:FindFirstChildOfClass("Humanoid")
 if h then h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; h.AutoRotate=false; h.EvaluateStateMachine=false end
 -- Reuse the court's lounge benches; no seat instances or seat welds are created.
 local court=workspace:FindFirstChild("PaddleUp")
 local benches={}
 if court then
  for _,item in ipairs(court:GetChildren()) do
   if item:IsA("BasePart") and item.Name=="Lounge seat" then table.insert(benches,item) end
  end
 end
 table.sort(benches,function(a,b) return a.Position.Z<b.Position.Z end)
 local cr=clone:FindFirstChild("HumanoidRootPart")
 local bench=benches[(slot-1)%math.max(1,#benches)+1]
 local function positionClone()
  if not bench or not cr then return end
  local row=math.floor((slot-1)/#benches)
  -- Three generous positions per ten-stud bench, centered along its long axis.
  local offset=({0,-3,3})[row%3+1]
  local thigh=clone:FindFirstChild("LeftUpperLeg") or clone:FindFirstChild("Left Leg")
  local inset=thigh and thigh.Size.Y*0.65 or 1
  local front=math.max(0,bench.Size.Z/2-inset)
  local center=bench.CFrame:PointToWorldSpace(Vector3.new(offset,bench.Size.Y/2,front))
  local forward=-bench.CFrame.LookVector
  local toward=Vector3.new(forward.X,0,forward.Z).Unit
  local pelvis=clone:FindFirstChild("LowerTorso") or clone:FindFirstChild("Torso")
  local height=pelvis and pelvis.Size.Y/2 or 1
  cr.CFrame=CFrame.lookAt(center+Vector3.yAxis*height,center+Vector3.yAxis*height+toward)
 end
 for _,item in ipairs(clone:GetDescendants()) do
  if item:IsA("BasePart") then
   item.Anchored=item==cr; item.Massless=true
   item.CanCollide=false; item.CanTouch=false; item.CanQuery=false
  elseif item:IsA("Motor6D") then item.Transform=CFrame.identity end
 end
 positionClone()
 clone.Parent=court or workspace
 -- Parenting a Humanoid initializes torso collision flags; clear them afterward.
 for _,item in ipairs(clone:GetDescendants()) do
  if item:IsA("BasePart") then item.CanCollide=false; item.CanTouch=false; item.CanQuery=false end
 end
 local animation=Instance.new("Animation")
 animation.Name="Spectator seated pose"
 -- Prefer the avatar's configured sit clip; Roblox's rig-specific sit is the fallback.
 local animate=character:FindFirstChild("Animate")
 local sit=animate and animate:FindFirstChild("sit")
 local source=sit and sit:FindFirstChildWhichIsA("Animation",true)
 animation.AnimationId=source and source.AnimationId or (h.RigType==Enum.HumanoidRigType.R6 and "rbxassetid://178130996" or "rbxassetid://2506281703")
 animation.Parent=clone
 local animator=h:FindFirstChildOfClass("Animator") or Instance.new("Animator",h)
 for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0) end
 h.Sit=true
 local track=animator:LoadAnimation(animation)
 track.Priority=Enum.AnimationPriority.Action; track.Looped=true; track:Play(0)
 local realHumanoid=character:FindFirstChildOfClass("Humanoid")
 local state={character=character,clone=clone,track=track,slot=slot,saved={},display=realHumanoid.DisplayDistanceType,rotate=realHumanoid.AutoRotate}
 active[player]=state
 -- Let the Animator resolve the pose before fitting the thighs to the cushion.
 task.spawn(function()
  local deadline=os.clock()+5
  repeat task.wait() until track.Length>0 or not clone.Parent or os.clock()>deadline
  if active[player]~=state or not clone.Parent or not bench then return end
  track.TimePosition=math.min(0.1,track.Length/2); track:AdjustSpeed(0)
  game:GetService("RunService").Heartbeat:Wait()
  game:GetService("RunService").Heartbeat:Wait()
  if active[player]~=state or not clone.Parent then return end
  local lowest=math.huge
  for _,name in ipairs(h.RigType==Enum.HumanoidRigType.R15 and {"LeftUpperLeg","RightUpperLeg"} or {"Left Leg","Right Leg"}) do
   local thigh=clone:FindFirstChild(name)
   if thigh then
    local cf,size=thigh.CFrame,thigh.Size
    local radius=(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2
    lowest=math.min(lowest,thigh.Position.Y-radius)
   end
  end
  if lowest<math.huge then
   local top=bench.Position.Y+bench.Size.Y/2
   cr.CFrame+=Vector3.yAxis*(top-lowest+0.03)
  end
 end)
 local function hide(item)
  local properties=snapshot(item); if not properties then return end
  state.saved[item]=properties
  if item:IsA("BasePart") then
   item.Transparency=1; item.CanCollide=false; item.CanTouch=false; item.CanQuery=false; item.CastShadow=false
   if item.Name=="HumanoidRootPart" then item.Anchored=true end
  elseif item:IsA("Decal") then item.Transparency=1 else item.Enabled=false end
 end
 state.connection=character.DescendantAdded:Connect(hide)
 for _,item in ipairs(character:GetDescendants()) do hide(item) end
 realHumanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None; realHumanoid.AutoRotate=false
 character:PivotTo(CFrame.new(0,185,600))
end
return Spectator
