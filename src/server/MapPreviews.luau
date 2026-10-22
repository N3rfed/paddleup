-- Publish scenery snapshots so map thumbnails work without uploaded image assets.
local Previews={}
function Previews.publish(court,rooftop,moon)
 local folder=Instance.new("Folder"); folder.Name="MapPreviews"
 local moonColors={
  ["Roof deck"]=Color3.fromRGB(72,82,98),["Court surround"]=Color3.fromRGB(48,59,77),
  ["Playing surface"]=Color3.fromRGB(48,89,107),Kitchen=Color3.fromRGB(57,127,140),
 }
 for _,name in ipairs({"Rooftop","Moon"}) do
  local model=Instance.new("Model"); model.Name=name
  local sources={}
  for _,child in ipairs(court:GetChildren()) do
   if child~=rooftop and child~=moon then table.insert(sources,child) end
  end
  table.insert(sources,name=="Moon" and moon or rooftop)
  local count=0
  for _,source in ipairs(sources) do
   local parts=source:IsA("BasePart") and {source} or source:GetDescendants()
   for _,part in ipairs(parts) do
    if part:IsA("BasePart") and part.Transparency<1 and math.abs(part.Position.X)<330
     and math.abs(part.Position.Z)<330 and part.Position.Y<420 then
     local copy=part:Clone()
     for _,child in ipairs(copy:GetChildren()) do
      if not child:IsA("DataModelMesh") and not child:IsA("Decal") and not child:IsA("SurfaceAppearance") then child:Destroy() end
     end
     copy.Anchored=true; copy.CanCollide=false; copy.CanTouch=false; copy.CanQuery=false
     if name=="Moon" and moonColors[copy.Name] then copy.Color=moonColors[copy.Name] end
     copy.Parent=model; count+=1
     if count%150==0 then task.wait() end
    end
   end
  end
  model.Parent=folder
 end
 folder.Parent=game:GetService("ReplicatedStorage")
end
return Previews
