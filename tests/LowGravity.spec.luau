-- Execute the actual server force helpers against a detached character.
return function(source)
 local first=assert(source:find("local function clearEnvironmentGravity(",1,true))
 local last=assert(source:find("local rotation=",first,true))
 local character=Instance.new("Model")
 local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Parent=character
 local player={Character=character}
 local users={[player]={side=1}}
 local environment=setmetatable({users=users,courtModifier="LowGravity"},{__index=getfenv()})
 local loader=assert(loadstring(source:sub(first,last-1).."\nreturn applyEnvironmentGravity"))
 setfenv(loader,environment)
 local apply=loader()
 local ok,result=pcall(function()
  apply(player,root)
  local force=assert(root:FindFirstChild("EnvironmentGravity"))
  assert(force.Attachment0.Parent==root and force.ApplyAtCenterOfMass,"Force belongs to the character")
  assert(math.abs(force.Force.Y-root.AssemblyMass*workspace.Gravity*0.5)<0.01,"Half gravity lift")
  apply(player,root)
  assert(root:FindFirstChild("EnvironmentGravity")==force and #root:GetChildren()==2,"Repeated updates reuse the force")
  users[player].side=0; apply(player,root)
  assert(#root:GetChildren()==0,"Lobby and spectator players retain normal gravity")
  users[player].side=1; apply(player,root)
  environment.courtModifier="None"; apply(player,root)
  assert(#root:GetChildren()==0,"Disabling the modifier removes force and attachment")
  return "Court force, reuse, lobby/spectator isolation, and cleanup passed"
 end)
 character:Destroy()
 assert(ok,result)
 return result
end
