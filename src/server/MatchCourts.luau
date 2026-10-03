local Courts={}
local names={
 ["Roof deck"]=true,["Court surround"]=true,["Playing surface"]=true,["Kitchen"]=true,
 ["Sideline"]=true,["Court line"]=true,["Service center line"]=true,["Net post"]=true,
 ["Net collision"]=true,["Net white tape"]=true,["Net cord"]=true,["RallyLights"]=true,
}
local function sceneryPart(parent,name,size,position,color,material,transparency)
 local part=Instance.new("Part")
 part.Name=name; part.Size=size; part.Position=position
 part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
 part.CastShadow=true; part.Color=color; part.Material=material
 if transparency then part.Transparency=transparency end
 part.Parent=parent
 return part
end

local function addEnvironment(court,offset,index)
 local environment=Instance.new("Model")
 environment.Name="CityEnvironment"
 environment.Parent=court
 local ground=Color3.fromRGB(53,91,73)
 local concrete=Color3.fromRGB(66,78,87)
 local glass=Color3.fromRGB(74,139,158)
 local groundPart=sceneryPart(environment,"District ground",Vector3.new(300,2,300),offset+Vector3.new(0,-22,0),ground,Enum.Material.Grass)
 groundPart.CastShadow=false

 -- A high-rise directly beneath the court places each roof in its own city block.
 sceneryPart(environment,"Skyline tower",Vector3.new(104,160,128),offset+Vector3.new(0,82,0),concrete,Enum.Material.Concrete)
 for floor=1,7 do
  local y=offset.Y+floor*19
  for _,side in ipairs({-1,1}) do
   sceneryPart(environment,"Tower window band",Vector3.new(0.4,9,112),offset+Vector3.new(side*52,y,0),glass,Enum.Material.Glass,0.22)
   sceneryPart(environment,"Tower window band",Vector3.new(92,9,0.4),offset+Vector3.new(0,y,side*64),glass,Enum.Material.Glass,0.22)
  end
 end

 -- Four shorter neighbors make the drop read as a city instead of empty sky.
 local heights={84,112,96,126}
 local positions={{-112,-112},{112,-112},{-112,112},{112,112}}
 for i,position in ipairs(positions) do
  local height=heights[(i+index-1)%#heights+1]
  local center=offset+Vector3.new(position[1],-20+height/2,position[2])
  sceneryPart(environment,"Neighborhood tower",Vector3.new(54,height,54),center,concrete,Enum.Material.Concrete)
  for floor=1,math.floor(height/22) do
   local y=center.Y-height/2+floor*22
   for _,side in ipairs({-1,1}) do
    sceneryPart(environment,"Neighborhood windows",Vector3.new(0.35,8,46),Vector3.new(center.X+side*27,y,center.Z),glass,Enum.Material.Glass,0.22)
    sceneryPart(environment,"Neighborhood windows",Vector3.new(46,8,0.35),Vector3.new(center.X,y,center.Z+side*27),glass,Enum.Material.Glass,0.22)
   end
  end
 end
end

function Courts.create(template,match)
 -- Pool slots map into five columns of eight separate city blocks.
 local index=match.slot+(match.pool=="2v2" and 20 or 0)
 local column=(index-1)%5
 local row=math.floor((index-1)/5)
 match.offset=Vector3.new(1050+column*330,0,-1155+row*330)
 local court=Instance.new("Model")
 court.Name="MatchCourt_"..match.id
 court:SetAttribute("MatchId",match.id)
 for _,instance in ipairs(template:GetChildren()) do
  if names[instance.Name] then
   local copy=instance:Clone()
   if copy:IsA("BasePart") then copy.CFrame+=match.offset end
   for _,part in ipairs(copy:GetDescendants()) do
    if part:IsA("BasePart") then part.CFrame+=match.offset end
   end
   copy.Parent=court
  end
 end
 addEnvironment(court,match.offset,index)
 court.Parent=workspace
 return court
end
return Courts
