-- Permanent arcade sunset. Keep the module name for existing server startup calls.
local Lighting = game:GetService("Lighting")
local DayNightCycle = {}
DayNightCycle.START_HOUR = 17.8

local function effect(className, name)
 local existing = Lighting:FindFirstChild(name)
 if existing and existing:IsA(className) then return existing end
 local item = Instance.new(className)
 item.Name = name
 item.Parent = Lighting
 return item
end

function DayNightCycle.start()
 -- Apply once: no heartbeat advances the clock after startup.
 Lighting.ClockTime = DayNightCycle.START_HOUR
 Lighting.GeographicLatitude = 35
 Lighting.GlobalShadows = true
 Lighting.Brightness = 2.2
 Lighting.ExposureCompensation = 0.05
 Lighting.Ambient = Color3.fromRGB(124, 120, 150)
 Lighting.OutdoorAmbient = Color3.fromRGB(161, 157, 177)
 Lighting.ColorShift_Top = Color3.fromRGB(239, 199, 180)
 Lighting.ColorShift_Bottom = Color3.fromRGB(52, 51, 76)
 Lighting.EnvironmentDiffuseScale = 0.45
 Lighting.EnvironmentSpecularScale = 0.75

 local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or effect("Atmosphere", "ArcadeSunsetAtmosphere")
 atmosphere.Color = Color3.fromRGB(225, 193, 204)
 atmosphere.Decay = Color3.fromRGB(118, 119, 161)
 atmosphere.Density = 0.29
 atmosphere.Offset = 0.1
 atmosphere.Haze = 1.4
 atmosphere.Glare = 0.2

 local sky = Lighting:FindFirstChildOfClass("Sky") or effect("Sky", "Sky")
 -- Built-in faces have no fixed sun baked into the image.
 for property, face in pairs({SkyboxBk="bk", SkyboxDn="dn", SkyboxFt="ft", SkyboxLf="lf", SkyboxRt="rt", SkyboxUp="up"}) do
  sky[property] = "rbxasset://textures/sky/sky512_" .. face .. ".tex"
 end
 sky.CelestialBodiesShown = true
 sky.SunAngularSize = 14
 sky.StarCount = 0

 local grade = effect("ColorCorrectionEffect", "ArcadeSunsetGrade")
 grade.Enabled = true
 grade.TintColor = Color3.fromRGB(255, 245, 250)
 grade.Brightness = 0.01
 grade.Contrast = 0.05
 grade.Saturation = 0.04

 -- Reuse the map's bloom so the base lighting does not stack two glow effects.
 local bloom = Lighting:FindFirstChild("ArcadeSunsetBloom") or Lighting:FindFirstChildOfClass("BloomEffect") or effect("BloomEffect", "ArcadeSunsetBloom")
 bloom.Enabled = true
 bloom.Intensity = 0.12
 bloom.Size = 32
 bloom.Threshold = 1.5

 local rays = effect("SunRaysEffect", "ArcadeSunsetRays")
 rays.Enabled = true
 rays.Intensity = 0.045
 rays.Spread = 0.8


 -- Clients restore this fixed rooftop profile after leaving the Moon.
 local profile = Lighting:FindFirstChild("RooftopProfile") or Instance.new("Folder")
 profile.Name = "RooftopProfile"
 profile.Parent = Lighting
 for _, property in ipairs({"ClockTime", "Brightness", "Ambient", "OutdoorAmbient",
  "ExposureCompensation", "ColorShift_Top", "ColorShift_Bottom",
  "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "FogEnd", "GeographicLatitude"}) do
  profile:SetAttribute(property, Lighting[property])
 end
 for _, property in ipairs({"Color", "Decay", "Density", "Haze", "Glare"}) do
  profile:SetAttribute("Atmosphere" .. property, atmosphere[property])
 end
end
return DayNightCycle
