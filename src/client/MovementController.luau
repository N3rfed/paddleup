local Players=game:GetService("Players")
local Config=require(script.Parent.MovementConfig)
local Controller={}
local character,root,humanoid,heading,joint,baseC0,waist,waistC0
local tracks={}
local velocity=Vector3.zero
local lean=CFrame.identity
local fov=0
local lastCut=0
local previousMove=Vector3.zero
local dust,sound
local enabled=false
local function alpha(rate,dt) return 1-math.exp(-rate*math.min(dt,0.1)) end
local function clear()
 if joint and joint.Parent then joint.C0=baseC0 end
 if waist and waist.Parent then waist.C0=waistC0 end
 for _,track in pairs(tracks) do track:Stop(0.1); track:Destroy() end
 if dust then dust.Parent:Destroy() end
 if sound then sound:Destroy() end
 tracks={}; dust=nil; sound=nil; joint=nil; waist=nil; velocity=Vector3.zero; lean=CFrame.identity
 previousMove=Vector3.zero
end
local function bind(c,r,h)
 clear(); character=c; root=r; humanoid=h
 for _,j in ipairs(c:GetDescendants()) do
  if j:IsA("Motor6D") and j.Part0==r then joint=j; baseC0=j.C0; break end
 end
 for _,j in ipairs(c:GetDescendants()) do
  if j:IsA("Motor6D") and j.Name:lower()=="waist" then waist=j; waistC0=j.C0; break end
 end
 local animator=h:FindFirstChildOfClass("Animator")
 if animator then
  for name,id in pairs(Config.Animations) do
   if id~="" then
    local animation=Instance.new("Animation"); animation.AnimationId=id
    local ok,track=pcall(function() return animator:LoadAnimation(animation) end)
    animation:Destroy()
    if ok then track.Priority=Enum.AnimationPriority.Movement; track.Looped=true; tracks[name]=track end
   end
  end
 end
 local attachment=Instance.new("Attachment",r); attachment.Name="CourtFootwork"; attachment.Position=Vector3.new(0,-h.HipHeight-r.Size.Y/2,0)
 dust=Instance.new("ParticleEmitter",attachment); dust.Enabled=false; dust.Texture="rbxasset://textures/particles/smoke_main.dds"
 dust.Lifetime=NumberRange.new(0.12,0.22); dust.Speed=NumberRange.new(0.5,1.5); dust.SpreadAngle=Vector2.new(70,70)
 dust.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.18),NumberSequenceKeypoint.new(1,0.5)})
 dust.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.8),NumberSequenceKeypoint.new(1,1)})
 if Config.SqueakId~="" then sound=Instance.new("Sound",r); sound.SoundId=Config.SqueakId; sound.Volume=0.18; sound.RollOffMaxDistance=35 end
end
function Controller.juice()
 if not enabled or not root then return end
 if dust and humanoid.FloorMaterial~=Enum.Material.Air then dust:Emit(5) end
 if sound then sound.PlaybackSpeed=Random.new():NextNumber(0.95,1.05); sound:Play() end
end
function Controller.recover()
 if root then local v=root.AssemblyLinearVelocity; velocity=Vector3.new(v.X,0,v.Z) end
end
function Controller.syncAim()
 if enabled and root and heading then root.CFrame=CFrame.new(root.Position)*heading end
end
-- Called by the existing render camera loop: heading never derives from movement.
function Controller.render(c,r,h,aimHeading,active,dt)
 if character~=c and c and r and h then bind(c,r,h) end
 enabled=active and h~=nil and h.Health>0
 heading=aimHeading
 if not enabled then
  if joint and joint.Parent then joint.C0=baseC0 end
 if waist and waist.Parent then waist.C0=waistC0 end
  for _,track in pairs(tracks) do track:Stop(0.12) end
  velocity=Vector3.zero; lean=CFrame.identity; fov=0
  return 0
 end
 h.AutoRotate=false
 r.CFrame=r.CFrame:Lerp(CFrame.new(r.Position)*heading,alpha(Config.AimResponse,dt))
 local v=r.AssemblyLinearVelocity
 local horizontal=Vector3.new(v.X,0,v.Z)
 local localV=r.CFrame:VectorToObjectSpace(horizontal)/math.max(h.WalkSpeed,1)
 local diving=c:GetAttribute("Diving")
 local target=diving and CFrame.identity or CFrame.Angles(math.rad(Config.LeanDegrees)*math.clamp(localV.Z,-1,1),0,-math.rad(Config.LeanDegrees)*math.clamp(localV.X,-1,1))
 lean=lean:Lerp(target,alpha(16,dt))
 if joint then joint.C0=baseC0*lean end
 -- Retain some chest lean instead of cancelling all athletic body motion.
 if waist then waist.C0=waistC0*CFrame.identity:Lerp(lean:Inverse(),0.45) end
 local move=h.MoveDirection
 if not diving and move.Magnitude>0.2 and previousMove.Magnitude>0.2 and move:Dot(previousMove)<0.2 and horizontal.Magnitude>6 and os.clock()-lastCut>0.25 then
  lastCut=os.clock(); Controller.juice()
 end
 previousMove=move
 local forward=move:Dot(r.CFrame.LookVector); local right=move:Dot(r.CFrame.RightVector)
 local state="Ready"
 if diving then state="Dive"
 elseif h.FloorMaterial==Enum.Material.Air then state=v.Y>0 and "Jump" or "Fall"
 elseif horizontal.Magnitude>0.8 and move.Magnitude>0.1 then
  state=forward>0.35 and "Forward" or forward< -0.35 and "Backward" or ""
  if math.abs(right)>0.35 then state..=right>0 and "Right" or "Left" end
 end
 local selected=tracks[state] or (state:find("Forward") and tracks.Forward) or (state:find("Backward") and tracks.Backward)
 for _,track in pairs(tracks) do
  if track==selected then
   if not track.IsPlaying then track:Play(0.12) end
   track:AdjustSpeed((state=="Ready" or state=="Jump" or state=="Fall" or diving) and 1 or math.clamp(horizontal.Magnitude/Config.ReferenceSpeed,0.25,1.8))
  elseif track.IsPlaying then track:Stop(0.12) end
 end
 local boost=(diving or (move.Magnitude>0.5 and horizontal.Magnitude>Config.ReferenceSpeed*0.9)) and Config.FOVBoost or 0
 fov+=(boost-fov)*alpha(9,dt)
 return fov
end
-- Run before physics, after default controls, without changing vertical jump velocity.
function Controller.step(dt)
 if not enabled or not root or not root.Parent or root.Anchored or character:GetAttribute("Diving") then return end
 local h=humanoid
 if h.FloorMaterial==Enum.Material.Air or h.WalkSpeed<=0 or Players.LocalPlayer:GetAttribute("PowerupStunned") then velocity=Vector3.zero; return end
 local desired=h.MoveDirection*h.WalkSpeed
 velocity=velocity:Lerp(desired,alpha(desired.Magnitude<velocity.Magnitude and Config.Deceleration or Config.Acceleration,dt))
 local v=root.AssemblyLinearVelocity
 root.AssemblyLinearVelocity=Vector3.new(velocity.X,v.Y,velocity.Z)
end
Players.LocalPlayer.CharacterRemoving:Connect(function() enabled=false; clear(); character=nil; root=nil end)
return Controller
