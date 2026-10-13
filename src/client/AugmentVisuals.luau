-- Local-only illusions never add physical obstacles or alter authoritative shots.
local Players=game:GetService("Players")
local Visuals={}
local clones={}
local hidden={}
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
