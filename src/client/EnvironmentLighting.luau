-- Moon presentation is local so lobby players retain the city lighting and scenery.
local EnvironmentLighting={}
function EnvironmentLighting.start(player)
 local Lighting=game:GetService("Lighting")
 local moon=false
 local saved={}
 local hidden={}
 local skies={}
 local connections={}
 local moonSky=Instance.new("Sky")
 moonSky.Name="LunarSky"; moonSky.CelestialBodiesShown=false; moonSky.StarCount=0
 -- Plain black backdrop; small world-space stars provide the only star imagery.
 for _,property in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp"}) do
  moonSky[property]="rbxassetid://134011288"
 end
 local lightProfile={ClockTime=14,Brightness=2.8,Ambient=Color3.fromRGB(61,65,73),
  OutdoorAmbient=Color3.fromRGB(91,95,103),ColorShift_Top=Color3.new(),ColorShift_Bottom=Color3.new(),
  ExposureCompensation=0,EnvironmentDiffuseScale=0.35,EnvironmentSpecularScale=0.6,FogEnd=100000,GeographicLatitude=12}
 local atmosphereProfile={Density=0,Haze=0,Glare=0,Color=Color3.fromRGB(200,210,230),Decay=Color3.fromRGB(90,100,120)}
 local function watch(instance,property,value)
  saved[instance]=saved[instance] or {}
  if saved[instance][property]==nil then saved[instance][property]=instance[property] end
  local function enforce() if moon and instance[property]~=value then instance[property]=value end end
  table.insert(connections,instance:GetPropertyChangedSignal(property):Connect(enforce))
  enforce()
 end
 local function hide(item)
  if item:IsA("BasePart") and hidden[item]==nil then
   hidden[item]=item.LocalTransparencyModifier; item.LocalTransparencyModifier=1
  end
 end
 local function city(root)
  for _,item in ipairs(root:GetDescendants()) do hide(item) end
  table.insert(connections,root.DescendantAdded:Connect(hide))
 end
 local function effect(item)
  if item==moonSky then return end
  if item:IsA("ColorCorrectionEffect") or item:IsA("SunRaysEffect") then watch(item,"Enabled",false)
  elseif item:IsA("Atmosphere") then for property,value in pairs(atmosphereProfile) do watch(item,property,value) end
  elseif item:IsA("Sky") then skies[item]=item.Parent; item.Parent=nil end
 end
 local function restore()
  for _,connection in ipairs(connections) do connection:Disconnect() end
  table.clear(connections)
  moonSky.Parent=nil
  local rooftop=Lighting:FindFirstChild("RooftopProfile")
  for instance,properties in pairs(saved) do
   for property,value in pairs(properties) do
    local key=instance==Lighting and property or instance:IsA("Atmosphere") and "Atmosphere"..property
    instance[property]=(key and rooftop and rooftop:GetAttribute(key)) or value
   end
  end
  for sky,parent in pairs(skies) do sky.Parent=parent end
  for item,value in pairs(hidden) do item.LocalTransparencyModifier=value end
  table.clear(saved); table.clear(skies); table.clear(hidden)
 end
 local function update()
  local mode=player:GetAttribute("SessionMode")
  local active=mode~=nil and mode~="Lobby" and workspace:GetAttribute("CourtEnvironment")=="Moon"
  if active==moon then return end
  moon=active
  if not moon then restore(); return end
  for property,value in pairs(lightProfile) do watch(Lighting,property,value) end
  for _,item in ipairs(Lighting:GetChildren()) do effect(item) end
  table.insert(connections,Lighting.ChildAdded:Connect(effect))
  moonSky.Parent=Lighting
  local starfield,twinkles
  local elapsed,pending=0,0
  table.insert(connections,game:GetService("RunService").Heartbeat:Connect(function(dt)
   elapsed+=dt; pending+=dt
   if pending<0.08 then return end
   pending=0
   local court=workspace:FindFirstChild("PaddleUp")
   local environment=court and court:FindFirstChild("MoonEnvironment")
   local sky=environment and environment:FindFirstChild("Lunar sky")
   if sky~=starfield then
    starfield=sky; twinkles={}
    if sky then
     for _,star in ipairs(sky:GetChildren()) do
      local phase=star:GetAttribute("TwinklePhase")
      if phase then table.insert(twinkles,{part=star,phase=phase,dot=star:FindFirstChild("Starlight") and star.Starlight:FindFirstChild("Point")}) end
     end
    end
   end
   for _,star in ipairs(twinkles or {}) do
    star.part.Transparency=0.12+0.48*(0.5+0.5*math.sin(elapsed*1.4+star.phase))^3
    if star.dot then star.dot.BackgroundTransparency=star.part.Transparency end
   end
  end))
  for _,name in ipairs({"PaddleUpLobby","LobbyCity","SkylineLobby"}) do local root=workspace:FindFirstChild(name); if root then city(root) end end
  table.insert(connections,workspace.ChildAdded:Connect(function(root)
   if root.Name=="PaddleUpLobby" or root.Name=="LobbyCity" or root.Name=="SkylineLobby" then city(root) end
  end))
 end
 local modeConnection=player:GetAttributeChangedSignal("SessionMode"):Connect(update)
 local environmentConnection=workspace:GetAttributeChangedSignal("CourtEnvironment"):Connect(update)
 update()
 return function()
  modeConnection:Disconnect(); environmentConnection:Disconnect()
  moon=false; restore(); moonSky:Destroy()
 end
end
return EnvironmentLighting
