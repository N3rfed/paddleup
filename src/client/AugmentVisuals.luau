-- Local-only illusions never add physical obstacles or alter authoritative shots.
local Players=game:GetService("Players")
local Visuals={}
local clones={}
local hidden={}
local auras={}
local bursts={}
function Visuals.activate(userId,tier)
 local p=Players:GetPlayerByUserId(userId)
 local root=p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
 if not root or (bursts[userId] and os.clock()-bursts[userId]<0.15) then return end
 bursts[userId]=os.clock()
 local sphere=Instance.new("Part")
 sphere.Name="Augment activation"; sphere.Shape=Enum.PartType.Ball; sphere.Material=Enum.Material.Neon
 sphere.Color=({Color3.fromRGB(198,213,230),Color3.fromRGB(255,211,93),Color3.fromRGB(197,137,255)})[tier] or Color3.new(1,1,1)
 sphere.Size=Vector3.new(2.5,2.5,2.5); sphere.CFrame=root.CFrame; sphere.Transparency=0.8
 sphere.Anchored=false; sphere.Massless=true; sphere.CanCollide=false; sphere.CanTouch=false; sphere.CanQuery=false; sphere.CastShadow=false
 sphere.Parent=root.Parent
 local weld=Instance.new("WeldConstraint",sphere); weld.Part0=root; weld.Part1=sphere
 game:GetService("TweenService"):Create(sphere,TweenInfo.new(0.5),{Size=Vector3.new(6,6,6),Transparency=1}):Play()
 game:GetService("Debris"):AddItem(sphere,0.55)
end
function Visuals.clone(userId)
 local p=Players:GetPlayerByUserId(userId)
 local character=p and p.Character
 if not character then return end
 local model=Instance.new("Model")
 model.Name="Dive Afterimage"
 -- Copy only rendered parts; scripts, humanoids, joints and sounds are excluded.
 for _,part in ipairs(character:GetDescendants()) do
  if part:IsA("BasePart") and part.Transparency<1 then
   local archivable=part.Archivable; part.Archivable=true
   local copy=part:Clone(); part.Archivable=archivable
   if copy then
    for _,child in ipairs(copy:GetChildren()) do
     if not child:IsA("DataModelMesh") and not child:IsA("Decal") and not child:IsA("SurfaceAppearance") then child:Destroy() end
    end
    copy.Anchored=true; copy.CanCollide=false; copy.CanTouch=false; copy.CanQuery=false
    copy.CFrame=part.CFrame; copy.LocalTransparencyModifier=0; copy.Parent=model
   end
  end
 end
 local outline=Instance.new("Highlight",model)
 outline.FillTransparency=1; outline.OutlineColor=Color3.fromRGB(163,128,255); outline.OutlineTransparency=0.4
 model.Parent=workspace
 table.insert(clones,{model=model,endsAt=os.clock()+2,player=p,character=character})
end
function Visuals.hidePaddle(userId,duration)
 local p=Players:GetPlayerByUserId(userId)
 local character=p and p.Character
 if not character then return end
 for _,name in ipairs({"PaddleFace","PaddleGrip"}) do
  local part=character:FindFirstChild(name)
  if part then
   local entry=hidden[part] or {previous=part.LocalTransparencyModifier,player=p,character=character}
   entry.endsAt=os.clock()+duration; hidden[part]=entry
   part.LocalTransparencyModifier=1
  end
 end
end
function Visuals.clear()
 for _,entry in ipairs(clones) do entry.model:Destroy() end
 table.clear(clones)
 for part,entry in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=entry.previous end end
 table.clear(hidden)
end
function Visuals.update()
 local now=os.clock()
 local present={}
 for _,player in ipairs(Players:GetPlayers()) do
  local tier=player:GetAttribute("ActiveAugmentTier") or 0
  local comeback=player:GetAttribute("ComebackBoost")==true
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local active=root and humanoid and humanoid.Health>0 and (player:GetAttribute("CourtSide") or 0)~=0 and (tier>0 or comeback)
  local aura=auras[player]
  if aura and (not active or aura.root~=root) then aura.attachment:Destroy(); auras[player]=nil; aura=nil end
  if active then
   present[player]=true
   if not aura then
    local attachment=Instance.new("Attachment",root); attachment.Name="Active augment aura"
    local particles=Instance.new("ParticleEmitter",attachment)
    particles.Texture="rbxasset://textures/particles/sparkles_main.dds"
    particles.Rate=14; particles.Lifetime=NumberRange.new(0.4,0.8); particles.Speed=NumberRange.new(1,2)
    particles.SpreadAngle=Vector2.new(180,180); particles.LightEmission=0.8; particles.LockedToPart=true
    particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.22),NumberSequenceKeypoint.new(1,0)})
    particles.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.25),NumberSequenceKeypoint.new(1,1)})
    local light=Instance.new("PointLight",attachment); light.Range=7; light.Brightness=0.5; light.Shadows=false
    aura={root=root,attachment=attachment,particles=particles,light=light}; auras[player]=aura
   end
   local color=comeback and Color3.fromRGB(70,225,255) or ({Color3.fromRGB(198,213,230),Color3.fromRGB(255,211,93),Color3.fromRGB(197,137,255)})[tier]
   aura.particles.Color=ColorSequence.new(color); aura.light.Color=color
   aura.light.Brightness=0.45+math.sin(now*3)*0.15
  end
 end
 for player,aura in pairs(auras) do
  if not present[player] then aura.attachment:Destroy(); auras[player]=nil end
 end
 for index=#clones,1,-1 do
  local entry=clones[index]
  if now>=entry.endsAt or entry.player.Character~=entry.character or entry.player:GetAttribute("CourtSide")==0 then
   entry.model:Destroy(); table.remove(clones,index)
  end
 end
 for part,entry in pairs(hidden) do
  if not part.Parent or now>=entry.endsAt or entry.player.Character~=entry.character or entry.player:GetAttribute("CourtSide")==0 then
   if part.Parent then part.LocalTransparencyModifier=entry.previous end
   hidden[part]=nil
  end
 end
end
return Visuals
