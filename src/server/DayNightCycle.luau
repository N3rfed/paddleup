-- Shared server lighting: one full day every twelve real-world minutes.
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local DayNightCycle = {}
DayNightCycle.CYCLE_SECONDS = 12 * 60
DayNightCycle.START_HOUR = 6

-- Matching midnight endpoints keep the wrap from night to dawn seamless.
local function frame(hour, brightness, ambient, outdoor, color, decay, density, haze, glare)
 return {hour=hour, brightness=brightness, ambient=Color3.fromRGB(unpack(ambient)),
  outdoor=Color3.fromRGB(unpack(outdoor)), color=Color3.fromRGB(unpack(color)),
  decay=Color3.fromRGB(unpack(decay)), density=density, haze=haze, glare=glare}
end
local frames = {
 frame(0, 0.6, {55,65,93}, {70,83,115}, {128,151,198}, {47,61,99}, 0.30, 1.2, 0),
 frame(5, 0.6, {55,65,93}, {70,83,115}, {128,151,198}, {47,61,99}, 0.30, 1.2, 0),
 frame(6, 1.3, {112,91,110}, {154,123,126}, {255,188,139}, {147,111,145}, 0.30, 1.8, 0.3),
 frame(8, 2.5, {132,145,166}, {153,158,173}, {220,232,245}, {130,148,174}, 0.26, 1, 0.15),
 frame(12, 3, {140,150,166}, {165,174,187}, {225,238,255}, {140,165,196}, 0.24, 0.8, 0.1),
 frame(16, 2.5, {132,145,166}, {153,158,173}, {239,210,181}, {130,148,174}, 0.26, 1, 0.2),
 frame(18, 1.5, {133,96,112}, {164,123,133}, {255,172,119}, {156,103,143}, 0.30, 1.8, 0.35),
 frame(20, 0.6, {55,65,93}, {70,83,115}, {128,151,198}, {47,61,99}, 0.30, 1.2, 0),
 frame(24, 0.6, {55,65,93}, {70,83,115}, {128,151,198}, {47,61,99}, 0.30, 1.2, 0),
}
local connection
function DayNightCycle.start()
 if connection then return end
 local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
 if not atmosphere then
  atmosphere = Instance.new("Atmosphere")
  atmosphere.Parent = Lighting
 end
 -- Use the built-in sky without the fixed sun baked into the custom skybox.
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
 Lighting.GlobalShadows = true
 Lighting.GeographicLatitude = 35
 local function apply(hour)
  local a, b = frames[1], frames[2]
  for i = 1, #frames - 1 do
   if hour >= frames[i].hour and hour < frames[i + 1].hour then
    a, b = frames[i], frames[i + 1]
    break
   end
  end
  local t = (hour - a.hour) / (b.hour - a.hour)
  t = t * t * (3 - 2 * t)
  local function blend(key) return a[key] + (b[key] - a[key]) * t end
  Lighting.ClockTime = hour
  Lighting.Brightness = blend("brightness")
  Lighting.Ambient = a.ambient:Lerp(b.ambient, t)
  Lighting.OutdoorAmbient = a.outdoor:Lerp(b.outdoor, t)
  atmosphere.Color = a.color:Lerp(b.color, t)
  atmosphere.Decay = a.decay:Lerp(b.decay, t)
  atmosphere.Density = blend("density")
  atmosphere.Haze = blend("haze")
  atmosphere.Glare = blend("glare")
 end
 local elapsed, pending = 0, 0
 apply(DayNightCycle.START_HOUR)
 connection = RunService.Heartbeat:Connect(function(dt)
  elapsed = (elapsed + dt) % DayNightCycle.CYCLE_SECONDS
  pending = pending + dt
  if pending < 0.1 then return end
  pending = pending % 0.1
  apply((DayNightCycle.START_HOUR + elapsed * 24 / DayNightCycle.CYCLE_SECONDS) % 24)
 end)
end
return DayNightCycle
