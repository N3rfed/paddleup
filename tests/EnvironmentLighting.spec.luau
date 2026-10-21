return function(EnvironmentLighting)
 local Lighting=game:GetService("Lighting")
 local signal=Instance.new("BindableEvent")
 local mode="Lobby"
 local player={GetAttribute=function() return mode end,GetAttributeChangedSignal=function() return signal.Event end}
 local originalEnvironment=workspace:GetAttribute("CourtEnvironment")
 local grade=Lighting:FindFirstChild("ArcadeSunsetGrade")
 local gradeEnabled=grade and grade.Enabled
 local roof=workspace.PaddleUpLobby:FindFirstChild("Building roof cap",true)
 local roofTransparency=roof and roof.LocalTransparencyModifier
 workspace:SetAttribute("CourtEnvironment","Moon")
 local stop=EnvironmentLighting.start(player)
 local ok,err=pcall(function()
  mode="Practice"; signal:Fire(); task.wait()
  assert(Lighting.ClockTime==14,"Moon uses a fixed sun position")
  assert(Lighting:FindFirstChild("LunarSky"),"Moon uses its own sky")
  if grade then assert(not grade.Enabled,"City sunset grading must not tint the moon") end
  if roof then assert(roof.LocalTransparencyModifier==1,"City roof cannot appear on moon floor") end
  Lighting.ClockTime=5; task.wait()
  assert(Lighting.ClockTime==14,"Server day/night replication cannot change moon lighting")
  mode="Lobby"; signal:Fire(); task.wait()
  assert(not Lighting:FindFirstChild("LunarSky"),"Lobby restores the city sky")
  if grade then assert(grade.Enabled==gradeEnabled,"Lobby restores city grading") end
  if roof then assert(roof.LocalTransparencyModifier==roofTransparency,"Lobby restores city geometry") end
  local profile=Lighting:FindFirstChild("RooftopProfile")
  if profile then assert(math.abs(Lighting.ClockTime-profile:GetAttribute("ClockTime"))<0.01,"Lobby restores the current city time") end
 end)
 stop(); signal:Destroy(); workspace:SetAttribute("CourtEnvironment",originalEnvironment)
 assert(ok,err)
 return "Moon lighting isolation, city roof hiding, and lobby restoration passed"
end
