-- Server-owned pickup lifecycle. onCollected(player, kind) is the future effect hook.
local Powerups = {}
Powerups.__index = Powerups

Powerups.SPAWN_INTERVAL = 8
Powerups.LIFETIME = 6
Powerups.FADE_SECONDS = 1.5
Powerups.DROP_SECONDS = 2.4
Powerups.PICKUP_RADIUS = 4

-- Stellate each octahedron face into a pyramid: eight points in all directions.
local function starPieces(model, template)
 local pieces = {}
 local triangles = {}
 for _,x in ipairs({-1,1}) do
  for _,y in ipairs({-1,1}) do
   for _,z in ipairs({-1,1}) do
    local vertices = {Vector3.new(x*0.8,0,0),Vector3.new(0,y*0.8,0),Vector3.new(0,0,z*0.8)}
    local tip = Vector3.new(x,y,z).Unit*1.7
    for index=1,3 do
     table.insert(triangles,{tip,vertices[index],vertices[index%3+1]})
    end
   end
  end
 end
 for index,triangle in ipairs(triangles) do
  local a,b,c = triangle[1],triangle[2],triangle[3]
  local ab,ac,bc = b-a,c-a,c-b
  if ab.Magnitude>ac.Magnitude and ab.Magnitude>bc.Magnitude then
   a,c = c,a
  elseif ac.Magnitude>bc.Magnitude then
   a,b = b,a
  end
  ab,ac,bc = b-a,c-a,c-b
  local right = ac:Cross(ab).Unit
  local back = bc.Unit
  local up = back:Cross(right).Unit
  local height = math.abs(ab:Dot(up))
  for _,half in ipairs({
   {frame=CFrame.fromMatrix((a+b)/2,right,up,back),length=math.abs(ab:Dot(back))},
   {frame=CFrame.fromMatrix((a+c)/2,-right,up,-back),length=math.abs(ac:Dot(back))},
  }) do
   local wedge = Instance.new("WedgePart")
   wedge.Name = "Star facet"
   wedge.Anchored = true
   wedge.CanCollide = false
   wedge.CanTouch = false
   wedge.CanQuery = false
   wedge.CastShadow = false
   wedge.Material = Enum.Material.SmoothPlastic
   wedge.Color = template.Color:Lerp(Color3.fromRGB(32,125,132),(index%3)*0.18)
   local size = Vector3.new(0.025,height,half.length)
   wedge.Size = size
   wedge.Parent = model
   table.insert(pieces,{part=wedge,frame=half.frame,size=size})
  end
 end
 return pieces
end

local function animateStar(pickup, center, scale, rotation, transparency)
 local frame = CFrame.new(center)*CFrame.Angles(0.3,rotation,0.2)
 for index,piece in ipairs(pickup.star) do
  piece.part.Size = piece.size*scale
  piece.part.CFrame = frame*CFrame.new(piece.frame.Position*scale)*piece.frame.Rotation
  piece.part.Transparency = transparency or 0
  -- Both halves of each triangular face share a hue; adjacent faces span the rainbow.
  piece.part.Color = Color3.fromHSV((rotation/3+math.floor((index-1)/2)/24)%1,0.8,1)
 end
end

function Powerups.new(parent, onCollected)
 local folder = Instance.new("Folder")
 folder.Name = "PowerupPickups"
 folder.Parent = parent
 return setmetatable({folder=folder, onCollected=onCollected, random=Random.new(), slots={}, bursts={}}, Powerups)
end

function Powerups:reset()
 self.folder:ClearAllChildren()
 table.clear(self.slots)
 table.clear(self.bursts)
end

function Powerups:spawn(side, now)
 local position = Vector3.new(self.random:NextNumber(-16,16),184,side*self.random:NextNumber(18,36))
 local model = Instance.new("Model")
 model.Name = "Placeholder Powerup"
 model:SetAttribute("PowerupKind", "Placeholder")
 model:SetAttribute("CourtSide", side)
 local orb = Instance.new("Part")
 orb.Name = "Pickup anchor"
 orb.Transparency = 1
 orb.Size = Vector3.new(2,2,2)
 orb.Material = Enum.Material.Neon
 orb.Color = Color3.fromRGB(110,245,218)
 orb.Anchored = true
 orb.CanCollide = false
 orb.CanTouch = false
 orb.CanQuery = false
 orb.CastShadow = false
 orb.Position = position + Vector3.new(0,8,0)
 orb.Parent = model
 model.PrimaryPart = orb
 local sparks = {}
 for index=1,4 do
  local spark = orb:Clone()
  spark.Name = "Orbit spark"
  spark.Transparency = 0
  spark.Shape = Enum.PartType.Block
  spark.Size = Vector3.new(0.3,0.3,0.3)
  spark.Color = Color3.fromRGB(245,225,145)
  spark.Parent = model
  sparks[index] = spark
 end
 local light = Instance.new("PointLight")
 light.Color = orb.Color
 light.Range = 8
 light.Brightness = 0.6
 light.Parent = orb
 local label = Instance.new("BillboardGui")
 label.Size = UDim2.fromOffset(160,42)
 label.StudsOffset = Vector3.new(0,2,0)
 label.MaxDistance = 65
 label.Parent = orb
 local text = Instance.new("TextLabel")
 text.Size = UDim2.fromScale(1,1)
 text.BackgroundTransparency = 1
 text.Font = Enum.Font.GothamBold
 text.TextSize = 12
 text.TextColor3 = Color3.fromRGB(235,255,246)
 text.TextStrokeTransparency = 0.4
 text.Text = "TEST POWERUP\nWalk into star to grab"
 text.Parent = label
 local pickup = {model=model, orb=orb, sparks=sparks, light=light, label=label, position=position, born=now}
 pickup.star = starPieces(model,orb)
 self:animate(pickup,0)
 model.Parent = self.folder
 return pickup
end

function Powerups:animate(pickup, age)
 local progress = math.clamp(age/self.DROP_SECONDS,0,1)
 local eased = progress*progress*(3-2*progress)
 local spiral = math.sin(progress*math.pi)*0.9
 local idle = math.max(0,age-self.DROP_SECONDS)
 local fade = math.clamp((idle-(self.LIFETIME-self.FADE_SECONDS))/self.FADE_SECONDS,0,1)
 local center = pickup.position+Vector3.new(math.sin(progress*math.pi*2)*spiral,
  8*(1-eased)+math.sin(idle*3)*0.25,math.cos(progress*math.pi*2)*spiral)
 pickup.orb.Position = center
 local beat = (1+math.sin(age*math.pi*2*1.5))/2
 local pulse = 1.8+beat*0.7
 pickup.orb.Size = Vector3.new(pulse,pulse,pulse)
 animateStar(pickup,center,pulse/2,age*0.9,fade)
 pickup.light.Color = Color3.fromHSV((age*0.3)%1,0.65,1)
 pickup.light.Brightness = (0.6+beat*1.2)*(1-fade)
 pickup.light.Range = 7+beat*3
 local text = pickup.label:FindFirstChildOfClass("TextLabel")
 if text then
  text.TextTransparency = fade
  text.TextStrokeTransparency = 0.4+0.6*fade
 end
 for index,spark in ipairs(pickup.sparks) do
  spark.Transparency = fade
  spark.Color = Color3.fromHSV((age*0.3+(index-1)/4)%1,0.75,1)
  local sparkSize = 0.22+beat*0.16
  spark.Size = Vector3.new(sparkSize,sparkSize,sparkSize)
  local angle = age*2+(index-1)*math.pi/2
  local radius = 1.65+beat*0.35
  spark.CFrame = CFrame.new(center+Vector3.new(math.cos(angle)*radius,math.sin(angle*2)*0.35,math.sin(angle)*radius))
   *CFrame.Angles(age*2,angle,math.pi/4)
 end
end

-- Claimed objects are already unavailable while their short visual burst finishes.
function Powerups:animateBursts(now)
 for index=#self.bursts,1,-1 do
  local burst = self.bursts[index]
  local t = math.clamp((now-burst.at)/0.45,0,1)
  local pickup = burst.pickup
  if t>=1 then
   pickup.model:Destroy()
   table.remove(self.bursts,index)
  else
   local size = 2*(1-t)+0.05
   pickup.orb.Size = Vector3.new(size,size,size)
   pickup.orb.Position = burst.center+Vector3.new(0,t*1.5,0)
   animateStar(pickup,pickup.orb.Position,size/2,(now-pickup.born)*0.9,t)
   pickup.light.Brightness = (1-t)*2
   for sparkIndex,spark in ipairs(pickup.sparks) do
    local angle = (sparkIndex-1)*math.pi/2
    spark.Position = burst.center+Vector3.new(math.cos(angle)*(1.7+t*3),t,math.sin(angle)*(1.7+t*3))
    spark.Transparency = t
   end
  end
 end
end

-- Participants are supplied by the authoritative court roster; spectators cannot collect.
function Powerups:update(now, participants)
 self:animateBursts(now)
 for _,side in ipairs({1,-1}) do
  local occupied = false
  for _,entry in ipairs(participants) do
   if entry.side == side then occupied = true; break end
  end
  local slot = self.slots[side]
  if not occupied then
   if slot and slot.pickup then slot.pickup.model:Destroy() end
   self.slots[side] = nil
   continue
  end
  if not slot then
   slot = {nextSpawn=now+2}
   self.slots[side] = slot
  end
  if not slot.pickup and now >= slot.nextSpawn then
   slot.pickup = self:spawn(side, now)
  end
  local pickup = slot.pickup
  if not pickup then continue end
  local age = now-pickup.born
  if age >= self.DROP_SECONDS+self.LIFETIME then
   pickup.model:Destroy()
   slot.pickup = nil
   slot.nextSpawn = now+self.SPAWN_INTERVAL
   continue
  end
  self:animate(pickup,age)
  if age < self.DROP_SECONDS then continue end
  for _,entry in ipairs(participants) do
   local character = entry.player.Character
   local root = character and character:FindFirstChild("HumanoidRootPart")
   local humanoid = character and character:FindFirstChildOfClass("Humanoid")
   if entry.side == side and root and humanoid and humanoid.Health > 0
    and (root.Position-pickup.orb.Position).Magnitude <= self.PICKUP_RADIUS then
    -- Remove before invoking the hook: only one player can claim this instance.
    slot.pickup = nil
    slot.nextSpawn = now+self.SPAWN_INTERVAL
    pickup.label.Enabled = false
    table.insert(self.bursts,{pickup=pickup,at=now,center=pickup.orb.Position})
    self:animateBursts(now)
    self.onCollected(entry.player, "Placeholder")
    break
   end
  end
 end
end

function Powerups:destroy()
 self:reset()
 self.folder:Destroy()
end

return Powerups
