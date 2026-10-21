-- Extend a real jump with a slow descent without changing ascent or lateral input.
local RunService=game:GetService("RunService")
local Rules=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MatchRules"))
local Controller={}

function Controller.start(player)
 local character,humanoid,root,stateConnection
 local jump,force,attachment
 local function enabled()
  return player:GetAttribute("SlowFallEnabled")==true
   and (player:GetAttribute("CourtSide") or 0)~=0 and player:GetAttribute("MatchVariant")=="Chaos"
 end
 local function clear()
  jump=nil
  if force then force:Destroy(); force=nil end
  if attachment then attachment:Destroy(); attachment=nil end
 end
 local function bind(c)
  clear()
  if stateConnection then stateConnection:Disconnect(); stateConnection=nil end
  character=c; humanoid=nil; root=nil
  local h=c:WaitForChild("Humanoid")
  local r=c:WaitForChild("HumanoidRootPart")
  if character~=c or player.Character~=c then return end
  humanoid=h; root=r
  stateConnection=h.StateChanged:Connect(function(_,state)
   if state==Enum.HumanoidStateType.Jumping and enabled() and not c:GetAttribute("Diving") then
    clear()
    jump={remaining=Rules.JUMP_HANG_TIME,airborne=false,age=0}
   elseif state==Enum.HumanoidStateType.Landed or state==Enum.HumanoidStateType.Dead
    or state==Enum.HumanoidStateType.Seated or state==Enum.HumanoidStateType.Swimming
    or state==Enum.HumanoidStateType.Climbing then clear() end
  end)
 end
 for _,attribute in ipairs({"SlowFallEnabled","CourtSide","MatchVariant"}) do
  player:GetAttributeChangedSignal(attribute):Connect(function() if not enabled() then clear() end end)
 end
 player.CharacterAdded:Connect(bind)
 player.CharacterRemoving:Connect(function()
  clear(); character=nil; humanoid=nil; root=nil
  if stateConnection then stateConnection:Disconnect(); stateConnection=nil end
 end)
 if player.Character then task.spawn(bind,player.Character) end
 RunService.PreSimulation:Connect(function(dt)
  if not jump then return end
  if not enabled() or not root or not root.Parent or humanoid.Health<=0 or root.Anchored
   or character:GetAttribute("Diving") then clear(); return end
  jump.age+=dt
  local airborne=humanoid.FloorMaterial==Enum.Material.Air
  if airborne then jump.airborne=true
  elseif jump.airborne or jump.age>0.3 then clear(); return end
  if not jump.airborne then return end
  if not force then
   if root.AssemblyLinearVelocity.Y>workspace.Gravity*dt then return end
   local velocity=root.AssemblyLinearVelocity
   root.AssemblyLinearVelocity=Vector3.new(velocity.X,0,velocity.Z)
   attachment=Instance.new("Attachment")
   attachment.Name="JumpHangAttachment"; attachment.Parent=root
   force=Instance.new("VectorForce")
   force.Name="JumpHangForce"; force.Attachment0=attachment
   force.RelativeTo=Enum.ActuatorRelativeTo.World; force.ApplyAtCenterOfMass=true
   force.Parent=root
  end
  if jump.remaining<=0 then clear(); return end
  -- Leave a little downward gravity so the avatar falls throughout the extra second.
  local gravity=workspace.Gravity*(player:GetAttribute("EnvironmentModifier")=="LowGravity" and 0.5 or 1)
  local lift=math.max(0,gravity-Rules.JUMP_DESCENT_GRAVITY)
  force.Force=Vector3.new(0,root.AssemblyMass*lift*math.min(1,jump.remaining/math.max(dt,1e-6)),0)
  jump.remaining-=dt
 end)
end

return Controller
