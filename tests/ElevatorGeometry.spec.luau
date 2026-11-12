return function(Geometry,Config)
 local root=Instance.new("Model")
 for _,name in ipairs({"1V1","2V2"}) do
  local bank=Instance.new("Model"); bank.Name=name; bank.Parent=root
  for i=1,3 do
   local frame=Instance.new("Part"); frame.Size=Vector3.new(12,13.5,2)
   frame.Position=Vector3.new((name=="1V1" and -52 or 52)+(i-2)*14,6.75,0)
   frame:SetAttribute("TeamFormat",name); frame.Parent=bank
   for _,dx in ipairs({-2.5,2.5}) do
    local door=Instance.new("Part"); door.Name="Brushed elevator door"; door.Size=Vector3.new(4.85,10.5,0.25)
    door.Position=frame.Position+Vector3.new(dx,-1.1,1.15); door.Anchored=true
    door.Material=Enum.Material.Metal; door.Parent=bank
   end
   local sign=Instance.new("Part"); sign.Name="CLASSIC label"; sign.Parent=bank
  end
 end
 local wrapper=Instance.new("Model"); root.Name="Elevator Banks"; root.Parent=wrapper
 for _,name in ipairs({"Reception feature wall","Ground floor rear wall"}) do
  local wall=Instance.new("Part"); wall.Name=name; wall.Size=Vector3.new(180,26,1)
  wall.Position=Vector3.new(0,13,-3); wall.Parent=wrapper
 end
 local controllers
 local ok,err=pcall(function()
  controllers=Geometry.build(wrapper,Config)
  assert(wrapper:GetAttribute("ExpectedDescendants")==#wrapper:GetDescendants(),"Arrival readiness reflects converted geometry, not removed legacy signs")
  local count=0
  for _,g in pairs(controllers) do
   for _,wall in ipairs(wrapper:GetDescendants()) do
    if wall:IsA("BasePart") and (wall.Name=="Reception feature wall" or wall.Name=="Ground floor rear wall") then
     local position=wall.CFrame:PointToObjectSpace(g.center.Position)
     assert(math.abs(position.X)>wall.Size.X/2 or math.abs(position.Y)>wall.Size.Y/2,
      "Structural walls do not block the cabin")
    end
   end
  end
  for _,g in pairs(controllers) do
   count+=1
   assert(#g.doors==4 and g.model:GetAttribute("Capacity")==g.config.capacity)
   assert(g:contains(g.entry.Position) and not g:contains(g.exit.Position),"Occupancy bounds separate exit")
   for _,d in ipairs(g.doors) do assert(d.part.Material==Enum.Material.Metal,"Original door material retained") end
   assert(g.model:GetAttribute("RecessedCabin") and g.model:GetAttribute("TelescopingDoors"))
   assert(g.model:FindFirstChild("Rooftop club plaque") and g.model:FindFirstChild("Cabin side handrail"),"Interior fittings are installed")
   local floor=g.origin:PointToObjectSpace(g.model["Cabin floor"].Position)
   assert(floor.Z<g.doorZ,"Cabin is behind its original doorway")
   for _,d in ipairs(g.doors) do
    for _,cf in ipairs({d.closed,d.opened}) do
     local x=g.origin:PointToObjectSpace(cf.Position).X
     assert(math.abs(x)+d.part.Size.X/2<=6,"Door motion stays inside the frame")
    end
   end
   g:setOpen(true)
  end
  assert(count==6,"Three functioning elevators per bank")
  task.wait(Config.DoorSeconds+0.1)
  for _,g in pairs(controllers) do
   for _,d in ipairs(g.doors) do assert((d.part.Position-d.opened.Position).Magnitude<0.01,"Tween stacks doors inside the pocket") end
   g:setOpen(false)
  end
  task.wait(Config.DoorSeconds+0.1)
  for _,g in pairs(controllers) do
   for _,d in ipairs(g.doors) do assert((d.part.Position-d.closed.Position).Magnitude<0.01,"Tween closes doors") end
  end
 end)
 if controllers then for _,g in pairs(controllers) do g:destroy() end end
 wrapper:Destroy()
 assert(ok,err)
 return "Six recessed elevators, interior fittings, capacity, bounds, and contained telescoping door tweens passed"
end
