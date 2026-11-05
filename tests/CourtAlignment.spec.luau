return function(World)
 local root=Instance.new("Model")
 local floor=Instance.new("Part",root);floor.Name="Playing surface";floor.Anchored=true
 floor.CFrame=CFrame.new(56.46,84.66,-6)*CFrame.Angles(0,0.3,0)
 local bench=Instance.new("Part",root);bench.Anchored=true
 bench.CFrame=floor.CFrame*CFrame.new(45,2,20)
 local relative=floor.CFrame:ToObjectSpace(bench.CFrame)
 local ok,err=pcall(function()
  World.alignCourt(root)
  assert((floor.Position-Vector3.new(0,181.16,0)).Magnitude<0.01,"The physical floor matches the server's court origin")
  assert(floor.CFrame.LookVector:Dot(CFrame.identity.LookVector)>0.9999)
  assert((floor.CFrame:ToObjectSpace(bench.CFrame).Position-relative.Position).Magnitude<0.01,"Furniture stays aligned to the court")
  local saved=bench.CFrame
  World.alignCourt(root)
  assert((bench.Position-saved.Position).Magnitude<0.001,"Repeated startup does not move the court again")
 end)
 root:Destroy();assert(ok,err)
end
