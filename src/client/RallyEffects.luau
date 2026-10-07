-- Cosmetic only: driven by authoritative contacts and replicated charge poses.
local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local TweenService=game:GetService("TweenService")
local Effects={}
Effects.__index=Effects
local IDLE=Color3.fromRGB(92,211,201)
local BLUE=Color3.fromRGB(55,155,255)
local WHITE=Color3.fromRGB(244,255,233)
local tiers={
 {1,Color3.fromRGB(245,255,126),Color3.fromRGB(255,235,90)},
 {1.1,Color3.fromRGB(100,255,160),Color3.fromRGB(25,200,130)},
 {1.3,Color3.fromRGB(255,175,65),Color3.fromRGB(255,95,35)},
 {1.6,Color3.fromRGB(255,85,110),Color3.fromRGB(205,40,80)},
 {2,Color3.fromRGB(225,130,255),Color3.fromRGB(150,55,255)},
}
local trails={}
for i,tier in ipairs(tiers) do trails[i]=ColorSequence.new(tier[2],tier[3]) end
local lobTrail=ColorSequence.new(BLUE,Color3.fromRGB(145,220,255))
local widths={}
for i=1,#tiers do widths[i]=NumberSequence.new({NumberSequenceKeypoint.new(0,1+(i-1)*0.12),NumberSequenceKeypoint.new(1,0)}) end

function Effects.palette(speed)
 for i=#tiers,1,-1 do
  if speed>=tiers[i][1] or i==1 then return tiers[i][2],i end
 end
end

local function part(name,parent)
 local p=Instance.new("Part")
 p.Name=name; p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false
 p.Material=Enum.Material.Neon; p.Size=Vector3.one*0.1; p.Transparency=1; p.Parent=parent
 return p
end

local function particles(parent)
 local emitter=Instance.new("ParticleEmitter")
 emitter.Name="Rally sparks"; emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
 emitter.Enabled=false; emitter.Rate=0; emitter.LightEmission=1; emitter.LightInfluence=0
 emitter.Lifetime=NumberRange.new(0.15,0.35); emitter.Speed=NumberRange.new(6,15)
 emitter.SpreadAngle=Vector2.new(75,75); emitter.Drag=5
 emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.32),NumberSequenceKeypoint.new(1,0)})
 emitter.Transparency=NumberSequence.new(0.1,1); emitter.Parent=parent
 return emitter
end

local function ribbon(parent,top,bottom,lifetime,owned)
 local a=Instance.new("Attachment"); a.Name="Rally trail start"; a.Position=top; a.Parent=parent
 local b=Instance.new("Attachment"); b.Name="Rally trail end"; b.Position=bottom; b.Parent=parent
 local trail=Instance.new("Trail")
 trail.Name="Rally motion"; trail.Attachment0=a; trail.Attachment1=b; trail.Lifetime=lifetime
 trail.Enabled=false; trail.FaceCamera=true; trail.LightEmission=0.85; trail.MinLength=0.05
 trail.Transparency=NumberSequence.new(0.4,1); trail.WidthScale=NumberSequence.new(1,0); trail.Parent=parent
 table.insert(owned,a); table.insert(owned,b); table.insert(owned,trail)
 return trail
end

function Effects.new(ball,trail)
 local self=setmetatable({ball=ball,trail=trail,actors={},transients={},lamps={},strips={},energy=0,
  color=IDLE,pulse=0,clock=0,cadence=1.4,scanAt=0,live=false},Effects)
 self.folder=Instance.new("Folder"); self.folder.Name="LocalRallyEffects"; self.folder.Parent=workspace
 self.bloom=Instance.new("BloomEffect")
 self.bloom.Name="RallyBloom"; self.bloom.Intensity=0.08; self.bloom.Size=20; self.bloom.Threshold=1.8; self.bloom.Parent=Lighting
 self.ballLight=Instance.new("PointLight")
 self.ballLight.Name="Rally glow"; self.ballLight.Range=8; self.ballLight.Brightness=0; self.ballLight.Shadows=false; self.ballLight.Parent=ball
 self.ballAttachment=Instance.new("Attachment"); self.ballAttachment.Name="Rally embers"; self.ballAttachment.Parent=ball
 self.embers=particles(self.ballAttachment); self.embers.Speed=NumberRange.new(0.5,2)
 self.embers.Lifetime=NumberRange.new(0.12,0.24); self.embers.SpreadAngle=Vector2.new(180,180)
 self.trail.FaceCamera=true; self.trail.LightEmission=0.8
 return self
end

function Effects:trackTransient(instance,lifetime)
 -- Bound both the instance count and the Lua references during long, fast rallies.
 if #self.transients>=24 then table.remove(self.transients,1).instance:Destroy() end
 table.insert(self.transients,{instance=instance,expires=self.clock+lifetime})
end

function Effects:ripple(position,color,size)
 local p=part("Bounce ripple",self.folder)
 p.Size=Vector3.new(0.8,0.02,0.8); p.Position=Vector3.new(position.X,181.36,position.Z)
 local surface=Instance.new("SurfaceGui")
 surface.Face=Enum.NormalId.Top; surface.CanvasSize=Vector2.new(128,128); surface.LightInfluence=0; surface.Parent=p
 local circle=Instance.new("Frame")
 circle.Size=UDim2.fromScale(0.85,0.85); circle.Position=UDim2.fromScale(0.075,0.075)
 circle.BackgroundTransparency=1; circle.Parent=surface
 local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0.5,0); corner.Parent=circle
 local stroke=Instance.new("UIStroke"); stroke.Color=color; stroke.Thickness=3; stroke.Transparency=0.15; stroke.Parent=circle
 TweenService:Create(p,TweenInfo.new(0.4),{Size=Vector3.new(size,0.02,size)}):Play()
 TweenService:Create(stroke,TweenInfo.new(0.4),{Transparency=1,Thickness=1}):Play()
 self:trackTransient(p,0.45)
end

function Effects:burst(position,direction,color,strength)
 local p=part("Paddle impact",self.folder)
 p.Shape=Enum.PartType.Ball; p.Size=Vector3.one*0.45; p.Color=color; p.Transparency=0.3
 p.CFrame=direction and direction.Magnitude>0.01 and CFrame.lookAt(position,position+direction) or CFrame.new(position)
 local attachment=Instance.new("Attachment"); attachment.Parent=p
 local sparks=particles(attachment)
 sparks.EmissionDirection=Enum.NormalId.Front; sparks.Color=ColorSequence.new(WHITE,color)
 sparks.Speed=NumberRange.new(7,12+strength*7); sparks:Emit(math.floor(6+strength*8))
 local light=Instance.new("PointLight")
 light.Color=color; light.Range=10; light.Brightness=1+strength; light.Shadows=false; light.Parent=p
 TweenService:Create(p,TweenInfo.new(0.22),{Size=Vector3.one*(1.5+strength*1.2),Transparency=1}):Play()
 TweenService:Create(light,TweenInfo.new(0.25),{Brightness=0}):Play()
 self:trackTransient(p,0.5)
end

function Effects:actor(character)
 if not character then return nil end
 if self.actors[character] then return self.actors[character] end
 local root=character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Body")
 local paddle=character:FindFirstChild("PaddleFace") or character:FindFirstChild("Paddle")
 if not root or not paddle then return nil end
 local actor={root=root,paddle=paddle,owned={},flash=0,swing=0,dive=0,lastPosition=root.Position}
 local highlight=Instance.new("Highlight")
 highlight.Name="Rally highlight"; highlight.Adornee=character; highlight.DepthMode=Enum.HighlightDepthMode.Occluded
 highlight.FillTransparency=1; highlight.OutlineTransparency=1; highlight.Enabled=false; highlight.Parent=character
 actor.highlight=highlight; table.insert(actor.owned,highlight)
 actor.paddleTrail=ribbon(paddle,Vector3.new(0,0.85,0),Vector3.new(0,-0.85,0),0.16,actor.owned)
 actor.motion={}
 for _,x in ipairs({-1,1}) do
  table.insert(actor.motion,ribbon(root,Vector3.new(x,0.2,0.4),Vector3.new(x,-0.35,0.4),0.22,actor.owned))
 end
 local attachment=Instance.new("Attachment"); attachment.Name="Paddle charge"; attachment.Parent=paddle
 table.insert(actor.owned,attachment)
 actor.charge=particles(attachment); actor.charge.Speed=NumberRange.new(0.5,2); actor.charge.SpreadAngle=Vector2.new(180,180)
 local light=Instance.new("PointLight"); light.Name="Paddle glow"; light.Range=6; light.Brightness=0; light.Parent=paddle
 actor.light=light; table.insert(actor.owned,light)
 self.actors[character]=actor
 return actor
end

function Effects:hitActor(userId)
 if userId then
  local player=Players:GetPlayerByUserId(userId)
  return self:actor(player and player.Character)
 end
 local world=workspace:FindFirstChild("PaddleUp")
 return self:actor(world and world:FindFirstChild("Practice Partner"))
end

function Effects:feedback(message,kind)
 if kind=="ballHit" then
  -- Tolerate a server still running the older position-only feedback payload.
  if typeof(message)=="Vector3" then message={position=message,speed=1} end
  if type(message)~="table" or typeof(message.position)~="Vector3" then return end
  if self.lastHit then self.cadence=self.cadence*0.6+math.clamp(self.clock-self.lastHit,0.25,3)*0.4 end
  self.lastHit=self.clock; self.hitZ=message.position.Z
  local color=Effects.palette(message.speed or 1)
  local strength=message.slam and 1.8 or message.powered and 1.5 or message.clean and 1.1 or 0.55
  strength+=0.35*(message.charge or 0)
  if message.soft then strength*=0.65 end
  self.pulse=math.min(1,strength); self.hitGlow=1
  self:burst(message.position,message.direction,color,strength)
  if message.slam then self:ripple(message.position,color,8) end
  local actor=self:hitActor(message.userId)
  if actor then actor.flash=1; actor.flashColor=color; actor.swing=self.clock+0.3 end
 elseif kind=="ballBounce" then
  self:ripple(message.position,Effects.palette(message.speed or 1),3.5)
 elseif kind=="swing" then
  local actor=self:hitActor(message.userId)
  if actor then actor.swing=self.clock+(message.slam and 0.4 or 0.24) end
 elseif kind=="diveMotion" then
  local actor=self:hitActor(message.userId)
  if actor then actor.dive=self.clock+0.5; actor.flash=0.5; actor.flashColor=BLUE end
 elseif kind=="rallyResult" then
  self:reset()
 end
end

function Effects:reset()
 self.lastHit=nil; self.cadence=1.4; self.pulse=0; self.hitGlow=0; self.live=false
 self.trail.Enabled=false; self.trail:Clear(); self.embers.Enabled=false; self.embers:Clear()
 for _,actor in pairs(self.actors) do
  actor.dive=0; actor.swing=0; actor.flash=0; actor.charge:Clear(); actor.charge.Enabled=false
  actor.paddleTrail.Enabled=false; actor.paddleTrail:Clear()
  for _,trail in ipairs(actor.motion) do trail.Enabled=false; trail:Clear() end
 end
end

function Effects:scan()
 local world=workspace:FindFirstChild("PaddleUp")
 local rig=world and world:FindFirstChild("RallyLights")
 if rig~=self.rig then
  self.rig=rig; table.clear(self.lamps); table.clear(self.strips)
  if rig then
   for _,p in ipairs(rig:GetChildren()) do
    if p.Name=="Court wash" then
     local light=p:FindFirstChildOfClass("SurfaceLight")
     if light then table.insert(self.lamps,{part=p,light=light,color=p.Color,lightColor=light.Color,brightness=light.Brightness}) end
    elseif p.Name=="Tempo strip" or p.Name=="End accent" then
     table.insert(self.strips,{part=p,color=p.Color,transparency=p.Transparency})
    end
   end
  end
 end
 for _,player in ipairs(Players:GetPlayers()) do
  if player:GetAttribute("CourtSide")~=0 then self:actor(player.Character) end
 end
 if world then self:actor(world:FindFirstChild("Practice Partner")) end
end

local function destroyActor(actor)
 for _,instance in ipairs(actor.owned) do instance:Destroy() end
end

function Effects:update(dt,snapshot,localChargeAt)
 if self.destroyed then return end
 self.clock+=dt
 if self.clock>=self.scanAt then self.scanAt=self.clock+0.5; self:scan() end
 for i=#self.transients,1,-1 do
  if self.clock>=self.transients[i].expires then self.transients[i].instance:Destroy(); table.remove(self.transients,i) end
 end
 local live=snapshot~=nil and snapshot.live==true
 if self.live and not live then self:reset() end
 if snapshot and (self.shotId~=snapshot.shotId or (live and not self.live)) then self.trail:Clear(); self.embers:Clear() end
 self.live=live; self.shotId=snapshot and snapshot.shotId
 local speed=snapshot and snapshot.speed or 1
 local color,tier=Effects.palette(speed)
 local hitAge=self.lastHit and self.clock-self.lastHit or 10
 local tempo=live and math.clamp((1.6-math.max(self.cadence,hitAge))/1.2,0,1) or 0
 local targetEnergy=live and math.clamp((speed-1)/1.2,0,1)*0.7+tempo*0.3 or 0
 local blend=1-math.exp(-dt*5)
 self.energy+=(targetEnergy-self.energy)*blend
 self.color=self.color:Lerp(live and color or IDLE,blend)
 self.pulse*=math.exp(-dt*6); self.hitGlow=(self.hitGlow or 0)*math.exp(-dt*9)
 -- Slow, shallow breathing plus contact waves, with no camera flashes or shake.
 local beat=(0.5+0.5*math.sin(self.clock*(0.45+tempo*0.8)*math.pi*2))*(0.04+self.energy*0.08)
 for _,entry in ipairs(self.lamps) do
  entry.part.Color=self.color
  entry.light.Color=Color3.fromRGB(220,239,230):Lerp(self.color,0.2+self.energy*0.3)
  entry.light.Brightness=0.85+self.energy*0.85+self.pulse*0.35+beat
 end
 for _,entry in ipairs(self.strips) do
  local age=hitAge-math.abs(entry.part.Position.Z-(self.hitZ or 0))/120
  local wave=self.lastHit and age>=0 and math.exp(-age*5) or 0
  entry.part.Color=self.color:Lerp(WHITE,wave*0.45)
  entry.part.Transparency=math.clamp(0.35-self.energy*0.16-wave*0.2-beat,0.04,0.4)
 end
 self.bloom.Intensity=0.08+self.energy*0.1+self.pulse*0.035
 local ballColor=snapshot and snapshot.slammable and BLUE or color
 self.ball.Color=ballColor:Lerp(WHITE,self.hitGlow*0.55)
 self.ballLight.Color=ballColor; self.ballLight.Brightness=live and (0.45+self.energy*1.1+self.hitGlow) or 0
 self.trail.Enabled=live==true
 local trailKey=tostring(tier)..tostring(snapshot and snapshot.slammable)
 if trailKey~=self.trailKey then
  self.trailKey=trailKey; self.trail.Color=snapshot and snapshot.slammable and lobTrail or trails[tier]
  self.trail.Lifetime=snapshot and snapshot.slammable and 0.7 or 0.35+(tier-1)*0.08
  self.trail.WidthScale=widths[tier]; self.embers.Color=ColorSequence.new(ballColor)
 end
 self.embers.Enabled=live and tier>=3; self.embers.Rate=8+(tier-1)*5
 local serverNow=workspace:GetServerTimeNow()
 for character,actor in pairs(self.actors) do
  if not character:IsDescendantOf(workspace) or not actor.root.Parent or not actor.paddle.Parent then
   destroyActor(actor); self.actors[character]=nil
  else
   local owner=Players:GetPlayerFromCharacter(character)
   local humanoid=character:FindFirstChildOfClass("Humanoid")
   local visible=actor.root.Name=="Body" and actor.root.Transparency<1 or (humanoid and humanoid.Health>0 and owner and owner:GetAttribute("CourtSide")~=0)
   local chargeAt=character:GetAttribute("ShotChargeAt")
   local chargeAge=chargeAt and serverNow-chargeAt or 0
   if owner==Players.LocalPlayer and localChargeAt then chargeAge=os.clock()-localChargeAt end
   local readyAt=character:GetAttribute("ChargedShotReadyAt") or 0
   local serving=snapshot and snapshot.serveReady and owner and owner.UserId==snapshot.serverId
   local charge=(live or serving) and visible and (serving or serverNow>=readyAt) and math.clamp((chargeAge-0.4)/0.6,0,1) or 0
   actor.flash*=math.exp(-dt*8)
   local diving=visible and self.clock<actor.dive
   local actorColor=diving and BLUE or charge>0 and color:Lerp(WHITE,charge*0.4) or (actor.flash>0.02 and actor.flashColor) or color
   local sequence=ColorSequence.new(actorColor)
   actor.highlight.Enabled=visible and (charge>0 or actor.flash>0.02) or false
   actor.highlight.FillColor=actorColor; actor.highlight.OutlineColor=actorColor
   actor.highlight.FillTransparency=1-math.max(charge*0.08,actor.flash*0.15)
   actor.highlight.OutlineTransparency=1-math.max(charge*0.6,actor.flash*0.8)
   actor.light.Color=actorColor; actor.light.Brightness=visible and (charge*1.2+actor.flash) or 0
   actor.charge.Color=sequence; actor.charge.Enabled=charge>0; actor.charge.Rate=charge*16
   actor.paddleTrail.Color=sequence; actor.paddleTrail.Enabled=visible and (charge>0.15 or self.clock<actor.swing) or false
   local distance=(actor.root.Position-actor.lastPosition).Magnitude
   local moving=distance/math.max(dt,0.001)>9 and distance<12
   actor.lastPosition=actor.root.Position
   for _,trail in ipairs(actor.motion) do
    trail.Color=sequence; trail.Enabled=visible and (diving or (live and self.energy>0.35 and moving)) or false
    if distance>=12 then trail:Clear(); actor.paddleTrail:Clear() end
   end
  end
 end
end

function Effects:destroy()
 if self.destroyed then return end
 self:reset(); self.destroyed=true
 for _,actor in pairs(self.actors) do destroyActor(actor) end
 table.clear(self.actors); table.clear(self.transients)
 for _,entry in ipairs(self.lamps) do
  if entry.part.Parent then entry.part.Color=entry.color; entry.light.Color=entry.lightColor; entry.light.Brightness=entry.brightness end
 end
 for _,entry in ipairs(self.strips) do
  if entry.part.Parent then entry.part.Color=entry.color; entry.part.Transparency=entry.transparency end
 end
 self.folder:Destroy(); self.bloom:Destroy(); self.ballLight:Destroy(); self.ballAttachment:Destroy()
end

return Effects
