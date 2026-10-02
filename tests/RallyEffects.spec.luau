-- Run in Studio with RallyEffects and World; fixtures are removed even on failure.
return function(Effects,World)
 local fixture=Instance.new("Model")
 fixture.Name="RallyEffectsTest"; fixture.Parent=workspace
 local ball=Instance.new("Part"); ball.Anchored=true; ball.Transparency=1; ball.Parent=fixture
 local trail=Instance.new("Trail"); trail.Parent=ball
 local effects
 local ok,result=pcall(function()
  World.updateLayout(fixture)
  local rig=fixture:FindFirstChild("RallyLights")
  assert(rig,"Saved courts must receive the lighting rig")
  World.updateLayout(fixture)
  assert(fixture:FindFirstChild("RallyLights")==rig,"Layout updates must preserve the existing rig")
  local washes=0
  for _,item in ipairs(rig:GetDescendants()) do
   if item:IsA("SurfaceLight") then washes+=1 end
   if item:IsA("BasePart") then assert(not item.CanCollide and not item.CanTouch and not item.CanQuery,"Lights must not affect gameplay") end
  end
  assert(washes==6,"Expected six court washes")

  effects=Effects.new(ball,trail)
  effects.scanAt=math.huge -- Isolate the test from real players and scenery.
  effects:update(1/60,nil) -- Joining before the first state packet must be safe.
  assert(not trail.Enabled)
  local character=Instance.new("Model"); character.Parent=fixture
  local body=Instance.new("Part"); body.Name="Body"; body.Anchored=true; body.Parent=character
  local paddle=Instance.new("Part"); paddle.Name="Paddle"; paddle.Anchored=true; paddle.Parent=character
  local actor=effects:actor(character)
  character:SetAttribute("ShotChargeAt",workspace:GetServerTimeNow()-1)
  local snapshot={live=true,speed=1,shotId=1,slammable=false}
  effects:update(0.1,snapshot)
  assert(actor.charge.Enabled,"Replicated charge must light the paddle")
  local calmEnergy=effects.energy
  snapshot.speed=2; snapshot.slammable=true
  effects:update(1,snapshot)
  assert(effects.energy>calmEnergy,"Faster rallies must increase lighting energy")
  assert(ball.Color==Color3.fromRGB(55,155,255),"Slammable lobs must retain their blue cue")
  assert(trail.Lifetime==0.7)
  local chargeLight=actor.light.Brightness
  character:SetAttribute("ChargedShotReadyAt",workspace:GetServerTimeNow()+2)
  effects:update(0.1,snapshot)
  assert(not actor.charge.Enabled and actor.light.Brightness<chargeLight,"Charge cooldown must suppress charge effects")
  character:SetAttribute("PerfectStreak",1)
  effects:update(0.1,snapshot)
  assert(actor.aura.Enabled and actor.highlight.Enabled,"Perfect streak must show an aura without charging")
  local initialRate=actor.aura.Rate
  character:SetAttribute("PerfectStreak",10)
  effects:update(0.1,snapshot)
  assert(actor.aura.Rate>initialRate,"Aura must grow with the streak")
  character:SetAttribute("PerfectStreak",0)
  effects:update(0.1,snapshot)
  assert(not actor.aura.Enabled,"Broken streak must disable the aura")

  local message={position=Vector3.new(0,185,20),direction=Vector3.new(0,0,-1),speed=2,clean=true,userId=-999999}
  for _=1,12 do effects:feedback(message,"ballHit"); effects:update(0.25,snapshot) end
  assert(effects.cadence<0.4,"Short exchanges must drive the tempo independently of speed")
  for _=1,40 do effects:feedback(message,"ballHit") end
  assert(#effects.transients<=24,"Impact instances must stay bounded")
  effects:feedback({position=Vector3.new(0,181.7,20),speed=2},"ballBounce")
  effects:feedback({},"rallyResult")
  snapshot.live=false
  effects:update(2,snapshot)
  assert(#effects.transients==0,"Expired impacts must be destroyed")
  assert(not trail.Enabled and not effects.embers.Enabled and effects.ballLight.Brightness==0)
  assert(not actor.highlight.Enabled and not actor.charge.Enabled and not actor.paddleTrail.Enabled)
  assert(not actor.aura.Enabled,"Rally end must disable the streak aura")
  assert(effects.energy<0.001,"Lighting must settle between rallies")
  character:Destroy(); effects:update(0.1,snapshot)
  assert(next(effects.actors)==nil,"Removed characters must release effect references")
  effects:destroy(); effects:destroy()
  assert(effects.folder.Parent==nil and effects.bloom.Parent==nil,"Teardown must remove local effects")
  return "Saved-court lights, speed/tempo response, blue lob cue, charge cooldown, bounded bursts, rally reset, and teardown passed"
 end)
 if effects then effects:destroy() end
 fixture:Destroy()
 assert(ok,result)
 return result
end
