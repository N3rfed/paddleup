-- Lobby-only orbit camera. Court aiming and spectator framing remain in init.client.
local LobbyCamera={}
function LobbyCamera.new(player,UIS)
 local self={active=false,dragging=false,root=nil,camera=nil,yaw=0,pitch=math.rad(-15),distance=17,stick=Vector2.zero}
 local touch,previousMouse,pinchDistance
 local MIN_ZOOM,MAX_ZOOM=7,28
 local function rotate(delta)
  self.yaw-=delta.X*0.004
  self.pitch=math.clamp(self.pitch-delta.Y*0.004,math.rad(-65),math.rad(35))
 end
 local function releaseDrag()
  self.dragging=false; previousMouse=nil; touch=nil; self.stick=Vector2.zero
  if self.active then UIS.MouseBehavior=Enum.MouseBehavior.Default end
 end
 UIS.InputBegan:Connect(function(input,processed)
  if not self.active or processed or UIS:GetFocusedTextBox() then return end
  if input.UserInputType==Enum.UserInputType.MouseButton2 then
   self.dragging=true
   previousMouse=Vector2.new(input.Position.X,input.Position.Y)
  elseif input.UserInputType==Enum.UserInputType.Touch and self.camera
   and input.Position.X>self.camera.ViewportSize.X*0.45 and not touch then
   touch=input
  elseif input.KeyCode==Enum.KeyCode.ButtonR3 then
   self.distance=self.distance>20 and 10 or self.distance>12 and 26 or 17
  end
 end)
 UIS.InputChanged:Connect(function(input,processed)
  if not self.active then return end
  if input.UserInputType==Enum.UserInputType.MouseMovement and self.dragging then
   local position=Vector2.new(input.Position.X,input.Position.Y)
   local delta=Vector2.new(input.Delta.X,input.Delta.Y)
   -- Some input sources provide absolute positions without a movement delta.
   if delta.Magnitude==0 and previousMouse then delta=position-previousMouse end
   previousMouse=position
   rotate(delta)
  elseif input.UserInputType==Enum.UserInputType.MouseWheel and not processed then
   self.distance=math.clamp(self.distance-input.Position.Z*2,MIN_ZOOM,MAX_ZOOM)
  elseif input==touch then
   rotate(Vector2.new(input.Delta.X,input.Delta.Y))
  elseif input.KeyCode==Enum.KeyCode.Thumbstick2 then
   self.stick=Vector2.new(input.Position.X,input.Position.Y)
  end
 end)
 UIS.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton2 then self.dragging=false; previousMouse=nil end
  if input==touch then touch=nil end
  if input.KeyCode==Enum.KeyCode.Thumbstick2 then self.stick=Vector2.zero end
 end)
 UIS.TouchPinch:Connect(function(_,scale,_,state,processed)
  if not self.active or processed then return end
  if state==Enum.UserInputState.Begin then pinchDistance=self.distance end
  if pinchDistance and scale>0 then self.distance=math.clamp(pinchDistance/scale,MIN_ZOOM,MAX_ZOOM) end
  if state==Enum.UserInputState.End or state==Enum.UserInputState.Cancel then pinchDistance=nil end
 end)
 UIS.WindowFocusReleased:Connect(releaseDrag)
 UIS.TextBoxFocused:Connect(releaseDrag)
 game:GetService("GuiService").MenuOpened:Connect(releaseDrag)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.RespectCanCollide=true
 function self:disable()
  if not self.active then return end
  releaseDrag(); self.active=false; self.root=nil; self.camera=nil; pinchDistance=nil
 end
 function self:update(camera,root,humanoid,dt)
  if not root or not humanoid or humanoid.Health<=0 then self:disable(); return end
  if not self.active or self.root~=root or self.camera~=camera then
   self:disable()
   self.active=true; self.root=root; self.camera=camera
   local look=root.CFrame.LookVector
   self.yaw=math.atan2(-look.X,-look.Z); self.pitch=math.rad(-15)
   player.CameraMode=Enum.CameraMode.Classic
  end
  if self.stick.Magnitude>0.15 then
   self.yaw-=self.stick.X*dt*2.5
   self.pitch=math.clamp(self.pitch+self.stick.Y*dt*2,math.rad(-65),math.rad(35))
  end
  humanoid.AutoRotate=true
  camera.CameraType=Enum.CameraType.Scriptable; camera.FieldOfView=70
  camera.CameraSubject=humanoid
  UIS.MouseBehavior=self.dragging and Enum.MouseBehavior.LockCurrentPosition or Enum.MouseBehavior.Default
  UIS.MouseIconEnabled=true
  local focus=root.Position+Vector3.new(0,2.5,0)
  local orbit=CFrame.Angles(0,self.yaw,0)*CFrame.Angles(self.pitch,0,0)
  local offset=-orbit.LookVector*self.distance
  params.FilterDescendantsInstances={player.Character}
  local hit=workspace:Raycast(focus,offset,params)
  if hit then offset=offset.Unit*math.max(0.5,hit.Distance-0.5) end
  local position=focus+offset
  camera.CFrame=CFrame.lookAt(position,focus)
  camera.Focus=CFrame.new(focus)
 end
 return self
end
return LobbyCamera
