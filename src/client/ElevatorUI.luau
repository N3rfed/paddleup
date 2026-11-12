local UI={}
function UI.start(player,network)
 local Players=game:GetService("Players")
 local RunService=game:GetService("RunService")
 local TweenService=game:GetService("TweenService")
 local UIS=game:GetService("UserInputService")
 local remote=network:WaitForChild("Elevator")
 local gui=Instance.new("ScreenGui"); gui.Name="ElevatorParty"; gui.ResetOnSpawn=false
 gui.DisplayOrder=90; gui.IgnoreGuiInset=true; gui.Parent=player:WaitForChild("PlayerGui")
 local dark=Color3.fromRGB(27,27,64); local cream=Color3.fromRGB(246,246,255); local cyan=Color3.fromRGB(80,232,255)
 local party,offer,notice,travel,viewport,travelCamera,travelStarted,arrivalPlayed,motor
 local function box(name,size,position)
  local f=Instance.new("Frame"); f.Name=name; f.Size=size; f.Position=position; f.AnchorPoint=Vector2.new(0.5,0.5)
  f.BackgroundColor3=dark; f.BorderSizePixel=0; f.Visible=false; f.Parent=gui
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,18); corner.Parent=f
  local stroke=Instance.new("UIStroke"); stroke.Color=cyan; stroke.Transparency=0.4; stroke.Parent=f
  return f
 end
 local panel=box("Party",UDim2.fromOffset(440,340),UDim2.fromScale(0.5,0.5))
 local invitation=box("Invitation",UDim2.fromOffset(440,210),UDim2.fromScale(0.5,0.5))
 local message=box("Status",UDim2.fromOffset(520,100),UDim2.fromScale(0.5,0.12))
 local function label(parent,name,y,height,text,size)
  local t=Instance.new("TextLabel"); t.Name=name; t.Position=UDim2.new(0,20,0,y); t.Size=UDim2.new(1,-40,0,height)
  t.BackgroundTransparency=1; t.TextColor3=cream; t.TextWrapped=true; t.Font=Enum.Font.GothamBold
  t.TextSize=size or 18; t.Text=text or ""; t.Parent=parent; return t
 end
 local function button(parent,name,text,x,y,width,callback)
  local b=Instance.new("TextButton"); b.Name=name; b.Position=UDim2.fromOffset(x,y); b.Size=UDim2.fromOffset(width,44)
  b.BackgroundColor3=cyan; b.TextColor3=dark; b.Font=Enum.Font.GothamBold; b.TextSize=17; b.Text=text
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=b
  b.Parent=parent; b.Activated:Connect(callback); return b
 end
 local title=label(panel,"Title",16,32,"",24)
 local status=label(panel,"Status",52,40)
 local roster=label(panel,"Roster",96,100,"",16)
 local ready=button(panel,"Ready","READY UP",20,210,400,function() if party then remote:FireServer("Ready",{revision=party.revision}) end end)
 local classic=button(panel,"Classic","Classic",20,210,194,function() if party then remote:FireServer("Vote",{revision=party.revision,mode="Classic"}) end end)
 local chaos=button(panel,"Chaotic","Chaotic",226,210,194,function() if party then remote:FireServer("Vote",{revision=party.revision,mode="Chaos"}) end end)
 button(panel,"Leave","Leave Elevator",20,274,400,function() remote:FireServer("Leave") end)
 local inviteTitle=label(invitation,"Title",16,44,"",22)
 local inviteDetail=label(invitation,"Detail",64,65,"",16)
 local function respond(accept)
  if offer then remote:FireServer("Response",{id=offer.id,accept=accept}); offer=nil; invitation.Visible=false end
 end
 button(invitation,"Accept","Accept",20,144,194,function() respond(true) end)
 button(invitation,"Decline","Decline",226,144,194,function() respond(false) end)
 local messageText=label(message,"Message",8,84,"",17)
 local overlay=Instance.new("CanvasGroup"); overlay.Name="ElevatorRide"; overlay.Size=UDim2.fromScale(1,1)
 overlay.BackgroundColor3=dark; overlay.Visible=false; overlay.GroupTransparency=1; overlay.Parent=gui
 local rideTitle=label(overlay,"Title",24,48,"GOING UP / ROOFTOP",26)
 local rideNames=label(overlay,"Travelers",82,50,"",18)
 local rideStatus=label(overlay,"Arrival",138,32,"",20)
 local stripes={}
 for i=1,8 do
  local strip=Instance.new("Frame"); strip.BorderSizePixel=0; strip.BackgroundColor3=cyan; strip.BackgroundTransparency=0.8
  strip.Size=UDim2.new(0,2,0.13,0); strip.Position=UDim2.fromScale(i/9,0); strip.Parent=overlay; stripes[i]=strip
 end
 local rideLeave=button(overlay,"LeaveElevator","Leave Elevator",20,24,170,function() remote:FireServer("Leave") end)
 rideLeave.ZIndex=5
 local function stopRide()
  travel=nil
  if motor then motor:Destroy(); motor=nil end
  local fade=TweenService:Create(overlay,TweenInfo.new(0.3),{GroupTransparency=1}); fade:Play()
  fade.Completed:Once(function() if not travel then overlay.Visible=false; if viewport then viewport:Destroy(); viewport=nil end end end)
 end
 local function startRide(data)
  travel=data; travelStarted=workspace:GetServerTimeNow(); arrivalPlayed=false
  if viewport then viewport:Destroy() end
  viewport=Instance.new("ViewportFrame"); viewport.Name="TravelingParty"; viewport.BackgroundTransparency=1
  viewport.Size=UDim2.new(1,0,1,-190); viewport.Position=UDim2.fromOffset(0,190); viewport.Parent=overlay
  viewport.Ambient=Color3.fromRGB(180,175,195); viewport.LightColor=cream
  local world=Instance.new("WorldModel"); world.Parent=viewport
  travelCamera=Instance.new("Camera"); travelCamera.CFrame=CFrame.lookAt(Vector3.new(0,5,15),Vector3.new(0,3,0))
  travelCamera.FieldOfView=55; travelCamera.Parent=viewport; viewport.CurrentCamera=travelCamera
  local function part(size,position,color)
   local p=Instance.new("Part"); p.Anchored=true; p.Size=size; p.Position=position; p.Color=color; p.Parent=world
  end
  part(Vector3.new(16,0.4,9),Vector3.new(0,-0.2,0),Color3.fromRGB(90,90,105))
  part(Vector3.new(16,10,0.4),Vector3.new(0,5,-4),Color3.fromRGB(164,164,183))
  local names={}
  for i,entry in ipairs(data.roster) do
   table.insert(names,entry.name)
   local p=Players:GetPlayerByUserId(entry.userId); local c=p and p.Character
   if c then
    local old=c.Archivable; c.Archivable=true; local clone=c:Clone(); c.Archivable=old
    if clone then
     for _,item in ipairs(clone:GetDescendants()) do
      if item:IsA("LuaSourceContainer") or item:IsA("Tool") then item:Destroy()
      elseif item:IsA("BasePart") then item.Anchored=true; item.CanCollide=false end
     end
     clone.Parent=world
     clone:PivotTo(CFrame.new((i-(#data.roster+1)/2)*3.2,3,0)*CFrame.Angles(0,math.pi,0))
    end
   end
  end
  rideNames.Text=table.concat(names,"  /  "); rideTitle.Text=(data.mode=="Chaos" and "CHAOTIC" or "CLASSIC").." / ROOFTOP"
  overlay.Visible=true; overlay.GroupTransparency=1
  -- Door closure completes before the ride fills the screen and movement audio begins.
  task.delay(data.doorSeconds or 0.65,function()
   if travel~=data then return end
   TweenService:Create(overlay,TweenInfo.new(0.25),{GroupTransparency=0}):Play()
   motor=Instance.new("Sound"); motor.Name="Elevator movement"; motor.SoundId=data.movementSound
   motor.Volume=0.22; motor.PlaybackSpeed=0.45; motor.Looped=true; motor.Parent=gui
   local rumble=Instance.new("EqualizerSoundEffect"); rumble.LowGain=4; rumble.MidGain=-12; rumble.HighGain=-40; rumble.Parent=motor
   motor:Play()
  end)
 end
 local function renderParty()
  if not party then panel.Visible=false; return end
  panel.Visible=party.stage~="Departing"
  title.Text=party.format:gsub("V","v").." ELEVATOR  /  "..party.count.."/"..party.capacity
  local names={}; local mine
  for _,entry in ipairs(party.roster) do
   table.insert(names,entry.name..(entry.ready and "  / READY" or "  / WAITING"))
   if entry.userId==player.UserId then mine=entry end
  end
  roster.Text=table.concat(names,"\n")
  local voting=party.stage=="Voting"
  ready.Visible=not voting and party.count==party.capacity
  ready.Text=mine and mine.ready and "READY  /  "..party.ready.."/"..party.capacity or "READY UP  /  "..party.ready.."/"..party.capacity
  ready.Active=not (mine and mine.ready)
  classic.Visible=voting; chaos.Visible=voting
  classic.Active=voting and party.allowed.Classic and not (mine and mine.vote)
  chaos.Active=voting and party.allowed.Chaos and not (mine and mine.vote)
  classic.BackgroundTransparency=classic.Active and 0 or 0.65; chaos.BackgroundTransparency=chaos.Active and 0 or 0.65
  classic.Text="Classic  /  "..party.counts.Classic; chaos.Text="Chaotic  /  "..party.counts.Chaos
  status.Text=voting and "VOTE / "..math.max(0,math.ceil(party.endsAt-workspace:GetServerTimeNow())).."s"
   or party.count<party.capacity and "Waiting for friends or invited solo players"
   or party.ready.."/"..party.capacity.." READY"
  if voting and (not party.allowed.Classic or not party.allowed.Chaos) then
   status.Text..=" / Matching the party's mode preferences"
  end
 end
 remote.OnClientEvent:Connect(function(data)
  if type(data)~="table" then return end
  if data.kind=="Party" then
   party=data; renderParty()
   if data.stage=="Departing" then if not travel then startRide(data) end
   elseif travel then stopRide() end
  elseif data.kind=="Closed" then party=nil; panel.Visible=false; if travel then stopRide() end
  elseif data.kind=="Invitation" then
   offer=data; invitation.Visible=true
   inviteTitle.Text="An opening is available in a "..data.format:gsub("V","v").." "..(data.replacement and "match!" or "party!")
  elseif data.kind=="InvitationClosed" then if offer and offer.id==data.id then offer=nil; invitation.Visible=false end
  elseif data.kind=="Notice" or data.kind=="Terminated" then
   notice=data; notice.untilAt=data.endsAt or workspace:GetServerTimeNow()+5; message.Visible=true
  end
 end)
 RunService.RenderStepped:Connect(function()
  local now=workspace:GetServerTimeNow()
  if party then renderParty() end
  if offer then
   local seconds=math.max(0,math.ceil(offer.endsAt-now))
   inviteDetail.Text=(offer.mode=="Chaos" and "Chaotic" or offer.mode=="Any" and "Any Mode" or offer.mode)
    .." / "..seconds.."s to respond\nYour current queue is retained until you accept."
   if seconds==0 then invitation.Visible=false end
  end
  if notice then
   messageText.Text=notice.message..(notice.endsAt and " ("..math.max(0,math.ceil(notice.endsAt-now))..")" or "")
   if now>=notice.untilAt then notice=nil; message.Visible=false end
  elseif player:GetAttribute("MatchPaused") then
   message.Visible=true; messageText.Text="MATCH PAUSED / Finding an approved replacement"
  else message.Visible=false end
  if travel then
   local remaining=travel.endsAt-now
   rideStatus.Text=remaining>1.2 and "Ascending..." or "ROOFTOP / ARRIVED"
   for i,strip in ipairs(stripes) do strip.Position=UDim2.fromScale(i/9,((now-travelStarted)*0.7+i*0.17)%1) end
   if travelCamera then travelCamera.CFrame=CFrame.lookAt(Vector3.new(math.sin(now*2)*0.045,5+math.sin(now*5)*0.025,15),Vector3.new(0,3,0)) end
   if remaining<=1.2 and not arrivalPlayed then
    arrivalPlayed=true; if motor then motor:Stop() end
    local ding=Instance.new("Sound"); ding.SoundId=travel.arrivalSound; ding.Volume=0.55; ding.Parent=gui; ding:Play()
    game:GetService("Debris"):AddItem(ding,3)
   end
  end
  if party or offer then UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true end
 end)
 local function resize()
  local camera=workspace.CurrentCamera; if not camera then return end
  local scale=math.min(1,(camera.ViewportSize.X-20)/520,(camera.ViewportSize.Y-30)/360)
  for _,f in ipairs({panel,invitation,message}) do
   local scaler=f:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",f); scaler.Scale=scale
  end
 end
 workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(resize)
 RunService.RenderStepped:Connect(resize)
end
return UI
