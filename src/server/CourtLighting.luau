-- Fixed evening presentation with bright, even lighting for play.
local Lighting = game:GetService("Lighting")
local CourtLighting = {}

function CourtLighting.start()
 Lighting.ClockTime = 20
 Lighting.Brightness = 2.5
 Lighting.Ambient = Color3.fromRGB(160,170,190)
 Lighting.OutdoorAmbient = Color3.fromRGB(175,185,205)
 Lighting.GlobalShadows = false
 Lighting.GeographicLatitude = 35
 Lighting.ExposureCompensation = 0

 local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
 if not atmosphere then
  atmosphere = Instance.new("Atmosphere")
  atmosphere.Parent = Lighting
 end
 atmosphere.Color = Color3.fromRGB(180,200,235)
 atmosphere.Decay = Color3.fromRGB(110,130,170)
 atmosphere.Density = 0.18
 atmosphere.Haze = 0.4
 atmosphere.Glare = 0

 local sky = Lighting:FindFirstChildOfClass("Sky")
 if not sky then
  sky = Instance.new("Sky")
  sky.Name = "Sky"
  sky.Parent = Lighting
 end
 for property, face in pairs({SkyboxBk="bk", SkyboxDn="dn", SkyboxFt="ft", SkyboxLf="lf", SkyboxRt="rt", SkyboxUp="up"}) do
  sky[property] = "rbxasset://textures/sky/sky512_" .. face .. ".tex"
 end
 sky.CelestialBodiesShown = true
end

return CourtLighting
