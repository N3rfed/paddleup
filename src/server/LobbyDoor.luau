local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local Door={}
local function pose(header,side,open)
 local width=header.Size.X/2
 return header.CFrame*CFrame.new(side*width*(open and 1.52 or 0.5),-header.Size.Y/2-6,0.45)
end

function Door.build(lobby)
 local exterior=lobby["Building Exterior"]
 if exterior:FindFirstChild("Sliding entrance") then return end
 local header=lobby.Architecture["Arrival glazing transom"]
 local doors=Instance.new("Model")
 doors.Name="Sliding entrance"
 for _,side in ipairs({-1,1}) do
  local panel=Instance.new("Part")
  panel.Name=side==-1 and "Left panel" or "Right panel"
  panel.Size=Vector3.new(header.Size.X/2,12,0.24)
  panel.CFrame=pose(header,side,false)
  panel.Material=Enum.Material.Glass; panel.Color=Color3.fromRGB(168,200,190)
  panel.Transparency=0.58; panel.Anchored=true; panel.CanTouch=false
  panel.Parent=doors
  for _,y in ipairs({-5.85,-0.5,5.85}) do
   local rail=Instance.new("Part")
   rail.Name="Brass rail"; rail.Size=Vector3.new(panel.Size.X,0.23,0.32)
   rail.CFrame=panel.CFrame*CFrame.new(0,y,0)
   rail.Color=Color3.fromRGB(166,139,89); rail.Material=Enum.Material.Metal
   rail.CanCollide=false; rail.CanTouch=false; rail.CanQuery=false; rail.Massless=true
   rail.Parent=panel
   local weld=Instance.new("WeldConstraint")
   weld.Part0=panel; weld.Part1=rail; weld.Parent=rail
  end
 end
 doors.Parent=exterior
end

function Door.start(lobby)
 local header=lobby.Architecture["Arrival glazing transom"]
 local doors=lobby["Building Exterior"]["Sliding entrance"]
 local panels={doors["Left panel"],doors["Right panel"]}
 local tweens={}
 local open=false
 for i,panel in ipairs(panels) do
  panel.CFrame=pose(header,2*i-3,false); panel.CanCollide=true
 end
 task.spawn(function()
  local closeAt=0
  while doors:IsDescendantOf(workspace) do
   local now=os.clock()
   for _,player in ipairs(Players:GetPlayers()) do
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then
     local offset=header.CFrame:PointToObjectSpace(root.Position)
     if math.abs(offset.X)<10 and math.abs(offset.Z)<15 and math.abs(offset.Y+13)<11 then
      closeAt=now+1
      break
     end
    end
   end
   local wanted=now<closeAt
   if wanted~=open then
    open=wanted
    for i,panel in ipairs(panels) do
     if tweens[i] then tweens[i]:Cancel() end
     panel.CanCollide=false
     local tween=TweenService:Create(panel,TweenInfo.new(0.45,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
      {CFrame=pose(header,2*i-3,open)})
     tweens[i]=tween
     if not open then
      tween.Completed:Once(function(state)
       if state==Enum.PlaybackState.Completed and not open then panel.CanCollide=true end
      end)
     end
     tween:Play()
    end
   end
   task.wait(0.1)
  end
 end)
end
return Door
