local Thumbnail={}
function Thumbnail.mount(parent,map)
 local image=Instance.new("Frame")
 image.Name="MapImage"; image.Position=UDim2.fromOffset(14,14); image.Size=UDim2.new(1,-28,0,132)
 image.BackgroundColor3=Color3.new(1,1,1); image.BorderSizePixel=0; image.ClipsDescendants=true; image.Parent=parent
 local rounding=Instance.new("UICorner",image); rounding.CornerRadius=UDim.new(0,8)
 local sky=Instance.new("UIGradient",image); sky.Rotation=90
 sky.Color=map=="Moon" and ColorSequence.new(Color3.fromRGB(8,12,32),Color3.fromRGB(47,54,96))
  or ColorSequence.new(Color3.fromRGB(91,168,218),Color3.fromRGB(226,228,242))
 if map=="Moon" then
  local random=Random.new(29)
  for index=1,18 do
   local star=Instance.new("Frame",image); star.BorderSizePixel=0
   star.BackgroundColor3=Color3.fromRGB(230,239,255); star.BackgroundTransparency=random:NextNumber(0.1,0.65)
   star.Position=UDim2.fromScale(random:NextNumber(),random:NextNumber(0,0.5)); star.Size=UDim2.fromOffset(index%3==0 and 2 or 1,1)
  end
 end
 local viewport=Instance.new("ViewportFrame")
 viewport.Name="Scenery"; viewport.Size=UDim2.fromScale(1,1); viewport.BackgroundTransparency=1
 viewport.BorderSizePixel=0; viewport.Ambient=map=="Moon" and Color3.fromRGB(145,158,194) or Color3.fromRGB(190,193,211)
 viewport.LightColor=map=="Moon" and Color3.fromRGB(204,224,255) or Color3.fromRGB(255,239,212)
 viewport.LightDirection=Vector3.new(-1,-0.7,-0.4); viewport.Parent=image
 local camera=Instance.new("Camera",viewport); camera.FieldOfView=58
 -- Lower, distinct three-quarter views keep the court large while revealing each setting.
 camera.CFrame=map=="Moon" and CFrame.lookAt(Vector3.new(-105,242,125),Vector3.new(-8,187,-27))
  or CFrame.lookAt(Vector3.new(83,238,112),Vector3.new(0,183,-15))
 viewport.CurrentCamera=camera
 local world=Instance.new("WorldModel",viewport)
 task.spawn(function()
  local previews=game:GetService("ReplicatedStorage"):WaitForChild("MapPreviews",60)
  local source=previews and previews:WaitForChild(map,10)
  if source and viewport.Parent then source:Clone().Parent=world end
 end)
 return image
end
return Thumbnail
