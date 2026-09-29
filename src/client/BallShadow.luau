-- A ground projection, independent of the sun, court lamps, and shadow quality.
local Shadow={}
Shadow.__index=Shadow

function Shadow.new()
 local anchor=Instance.new("Part")
 anchor.Name="Ball ground shadow"; anchor.Size=Vector3.new(2,0.02,2)
 anchor.Anchored=true; anchor.Transparency=1; anchor.CastShadow=false
 anchor.CanCollide=false; anchor.CanQuery=false; anchor.CanTouch=false
 local surface=Instance.new("SurfaceGui")
 surface.Name="Shadow"; surface.Face=Enum.NormalId.Top; surface.CanvasSize=Vector2.new(128,128)
 surface.LightInfluence=0; surface.AlwaysOnTop=false; surface.Enabled=false; surface.Parent=anchor
 -- Concentric translucent disks give a soft edge without an external texture.
 for i=1,5 do
  local disk=Instance.new("Frame")
  disk.AnchorPoint=Vector2.new(0.5,0.5); disk.Position=UDim2.fromScale(0.5,0.5)
  local size=1-(i-1)*0.14
  disk.Size=UDim2.fromScale(size,size); disk.BackgroundColor3=Color3.new(0,0,0)
  disk.BackgroundTransparency=0.84; disk.BorderSizePixel=0; disk.Parent=surface
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0.5,0); corner.Parent=disk
 end
 anchor.Parent=workspace
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Include
 return setmetatable({anchor=anchor,surface=surface,params=params,scanAt=0,ground={}},Shadow)
end

function Shadow:update(position,visible)
 self.surface.Enabled=visible==true and position~=nil
 if not self.surface.Enabled then return end
 if os.clock()>=self.scanAt then
  self.scanAt=os.clock()+1; table.clear(self.ground)
  local world=workspace:FindFirstChild("PaddleUp")
  if world then
   -- Ignore players, the net, and fixtures so the projection stays on the floor.
   for _,p in ipairs(world:GetChildren()) do
    if p:IsA("BasePart") and (p.Name=="Playing surface" or p.Name=="Kitchen" or p.Name=="Court surround" or p.Name=="Roof deck") then
     table.insert(self.ground,p)
    end
   end
  end
  self.params.FilterDescendantsInstances=self.ground
 end
 local hit=workspace:Raycast(Vector3.new(position.X,190,position.Z),Vector3.new(0,-20,0),self.params)
 local floor=hit and hit.Position.Y or 181.28
 local height=math.max(0,position.Y-floor)
 local size=1.45+math.min(height,25)*0.025
 self.anchor.Size=Vector3.new(size,0.02,size)
 self.anchor.Position=Vector3.new(position.X,floor+0.035,position.Z)
end

function Shadow:destroy() self.anchor:Destroy() end
return Shadow
