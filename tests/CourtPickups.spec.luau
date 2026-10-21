return function(Powerups)
 local parent = Instance.new("Folder")
 local character = Instance.new("Model")
 local root = Instance.new("Part")
 root.Name = "HumanoidRootPart"
 root.Parent = character
 local humanoid = Instance.new("Humanoid")
 humanoid.Parent = character
 local player = {Character=character}
 local collected = 0
 local system = Powerups.new(parent,function(who,kind)
  assert(who == player and kind == "Placeholder")
  collected += 1
 end)
 local ok,err = pcall(function()
  system:update(0,{})
  assert(#system.folder:GetChildren() == 0,"Empty courts must not spawn")
  local roster = {{player=player,side=1},{player=player,side=1}}
  system:update(0,roster)
  system:update(2,roster)
  local pickup = system.slots[1].pickup
  assert(pickup and #system.folder:GetChildren() == 1,"One orb per occupied half")
  assert(#pickup.star == 48,"Eight pyramid points have 24 triangular faces")
  assert(math.abs(pickup.position.X)<=16 and pickup.position.Z>=18 and pickup.position.Z<=36)
  root.Position = pickup.orb.Position
  system:update(2.1,roster)
  assert(collected == 0,"Cannot collect during drop")
  root.Position = pickup.position
  humanoid.Health = 0
  system:update(3.2,roster)
  assert(math.abs(pickup.orb.Position.Y-pickup.position.Y-4)<0.01,"Slow descent is halfway down after 1.2 seconds")
  assert(#pickup.sparks == 4,"Custom orbit animation has four sparks")
  system:update(4.5,roster)
  assert(collected == 0,"Dead players cannot collect")
  humanoid.Health = 100
  root.Position = pickup.position+Vector3.new(3.6,0,0)
  system:update(4.6,roster)
  assert(collected == 1 and system.slots[1].pickup == nil,"Wider pickup radius accepts a passing player exactly once")
  assert(#system.bursts == 1 and not pickup.label.Enabled,"Collection plays a burst without a pickup label")
  system:update(4.8,roster)
  assert(collected == 1 and pickup.star[1].part.Transparency > 0,"Burst fades and cannot be collected twice")
  system:update(5.1,roster)
  assert(#system.bursts == 0,"Completed bursts are cleaned up")
  assert(#system.folder:GetChildren() == 0,"Respawn cooldown")
  root.Position = Vector3.zero
  system:update(12.7,roster)
  assert(system.slots[1].pickup,"Collected pickups respawn")
  local expiring = system.slots[1].pickup
  system:update(19.6,roster)
  assert(expiring.star[1].part.Transparency < 0.001,"Floor lifetime starts after descent")
  system:update(20.35,roster)
  assert(math.abs(expiring.star[1].part.Transparency-0.5)<0.001,"Expiry gradually fades the star")
  assert(math.abs(expiring.sparks[1].Transparency-0.5)<0.001,"Sparks fade with the star")
  assert(math.abs(expiring.label.TextLabel.TextTransparency-0.5)<0.001,"Label fades with the star")
  system:update(21.2,roster)
  assert(system.slots[1].pickup == nil,"Unclaimed pickups expire")
  system:update(29.3,roster)
  assert(system.slots[1].pickup,"Expired pickups respawn")
  system:update(30,{{player=player,side=0}})
  assert(#system.folder:GetChildren() == 0,"Spectators do not keep pickups alive")
  system:update(31,roster)
  system:update(33,roster)
  system:reset()
  assert(next(system.slots) == nil and #system.folder:GetChildren() == 0,"Reset removes all state")
 end)
 system:destroy()
 character:Destroy()
 parent:Destroy()
 assert(ok,err)
 return "Powerup spawn, collection, expiry, respawn, and cleanup passed"
end
