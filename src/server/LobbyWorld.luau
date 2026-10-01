local LobbyWorld={}
function LobbyWorld.build()
 local existing=workspace:FindFirstChild("SkylineLobby")
 if existing and existing:GetAttribute("Version")==2 then return existing end
 if existing then existing:Destroy() end
 local root=Instance.new("Model"); root.Name="SkylineLobby"
 root:SetAttribute("Version",2)
 local function part(name,size,pos,color,material)
  local p=Instance.new("Part"); p.Name=name; p.Size=size; p.Position=pos
  p.Anchored=true; p.Color=color; p.Material=material or Enum.Material.SmoothPlastic; p.Parent=root
  return p
 end
 local dark=Color3.fromRGB(23,43,50)
 local mint=Color3.fromRGB(92,233,190)
 local cream=Color3.fromRGB(231,223,202)
 part("Lobby terrace",Vector3.new(62,3,76),Vector3.new(112,179.5,0),cream,Enum.Material.Concrete)
 part("Lobby tower",Vector3.new(58,176,72),Vector3.new(112,90,0),dark,Enum.Material.Concrete)
 for _,x in ipairs({81,143}) do
  part("Terrace railing",Vector3.new(0.5,4,76),Vector3.new(x,183,0),dark)
  part("Mint rail",Vector3.new(0.6,0.15,76),Vector3.new(x,185,0),mint,Enum.Material.Neon)
 end
 for _,z in ipairs({-38,38}) do part("End railing",Vector3.new(62,4,0.5),Vector3.new(112,183,z),dark) end
 for _,x in ipairs({93,131}) do
  for _,z in ipairs({-24,24}) do
   part("Planter",Vector3.new(6,3,6),Vector3.new(x,182.5,z),dark)
   local tree=part("Topiary",Vector3.new(6,7,6),Vector3.new(x,187,z),Color3.fromRGB(57,113,82),Enum.Material.Grass)
   tree.Shape=Enum.PartType.Ball
  end
  part("Lounge bench",Vector3.new(5,2,18),Vector3.new(x,182,0),dark)
  part("Bench cushion",Vector3.new(5.2,0.4,18),Vector3.new(x,183.2,0),mint)
 end
 local sign=part("Club lobby sign",Vector3.new(29,9,0.6),Vector3.new(112,189,-30),dark)
 local surface=Instance.new("SurfaceGui",sign); surface.Face=Enum.NormalId.Back; surface.CanvasSize=Vector2.new(900,280)
 local label=Instance.new("TextLabel",surface); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
 label.Text="PADDLE UP!\nSKYLINE SOCIAL CLUB\nPLAY  /  PARTY UP  /  WATCH"; label.TextColor3=mint
 label.Font=Enum.Font.GothamBold; label.TextSize=44
 for _,station in ipairs({
  {x=89,name="Singles",mode="1v1",color=mint},
  {x=104,name="Doubles",mode="2v2",color=Color3.fromRGB(107,182,249)},
  {x=120,name="Practice",mode="Practice",color=Color3.fromRGB(249,177,109)},
  {x=135,name="Spectate",mode="Spectate",color=Color3.fromRGB(184,157,244)},
 }) do
  part(station.name.." queue pad",Vector3.new(8,0.15,8),Vector3.new(station.x,181.1,-14),station.color,Enum.Material.Neon)
  local kiosk=part(station.name.." station",Vector3.new(6,5,1.5),Vector3.new(station.x,183.5,-18),dark)
  kiosk:SetAttribute("LobbyStation",station.mode)
  local board=Instance.new("SurfaceGui",kiosk); board.Face=Enum.NormalId.Back; board.CanvasSize=Vector2.new(360,240)
  local title=Instance.new("TextLabel",board); title.Size=UDim2.fromScale(1,1); title.BackgroundTransparency=1
  title.Text=string.upper(station.name).."\n"..(station.mode=="Practice" and "EASY / NORMAL / HARD" or station.mode=="Spectate" and "WATCH THE COURT" or "SOLO OR WITH FRIENDS")
  title.TextColor3=station.color; title.Font=Enum.Font.GothamBold; title.TextSize=27; title.TextWrapped=true
  local prompt=Instance.new("ProximityPrompt",kiosk); prompt.ObjectText=station.name
  prompt.ActionText=station.mode=="Spectate" and "Watch match" or "Open queue"
  prompt.HoldDuration=0; prompt.MaxActivationDistance=10; prompt.RequiresLineOfSight=false
 end
 local spawn=Instance.new("SpawnLocation"); spawn.Name="Lobby arrival"; spawn.Size=Vector3.new(8,0.2,8)
 spawn.Position=Vector3.new(112,181.2,20); spawn.Anchored=true; spawn.Neutral=true; spawn.Duration=0
 spawn.Color=mint; spawn.Material=Enum.Material.Neon; spawn.Parent=root
 root.Parent=workspace
 return root
end
return LobbyWorld
