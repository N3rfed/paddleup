local Assets=require(script.Parent:WaitForChild("FigmaAssets"))
local Deck=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ArcadeDeck"))
local Slots={}
function Slots.start(player,network)
 local UIS=game:GetService("UserInputService")
 local RunService=game:GetService("RunService")
 local remote=network:WaitForChild("Arcade")
 local state,received,stamina=nil,0,nil
 local buttons={}
 local root=Instance.new("Frame"); root.Name="ArcadeSlots"; root.BackgroundTransparency=1
 root.Position=UDim2.fromOffset(539,-38); root.Size=UDim2.fromOffset(300,158)
 local glow=Instance.new("ColorCorrectionEffect",game:GetService("Lighting"))
 glow.Name="ArcadeGlowBall"; glow.Enabled=false; glow.Brightness=-0.15; glow.TintColor=Color3.fromRGB(195,188,255)
 local lamp
 local chaosGui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
 chaosGui.Name="ChaosEvents"; chaosGui.ResetOnSpawn=false; chaosGui.DisplayOrder=25
 local chaosBanner=Instance.new("Frame",chaosGui); chaosBanner.Name="Event"
 chaosBanner.AnchorPoint=Vector2.new(0.5,0); chaosBanner.Position=UDim2.fromScale(0.5,0.12)
 chaosBanner.Size=UDim2.fromOffset(320,64); chaosBanner.BackgroundColor3=Color3.fromRGB(13,19,31)
 chaosBanner.BorderSizePixel=0; chaosBanner.Visible=false
 Instance.new("UICorner",chaosBanner).CornerRadius=UDim.new(0,8)
 local eventTitle,eventDetail
 local function label(parent,name,value,x,y,w,h,size)
  local t=Instance.new("TextLabel",parent); t.Name=name; t.BackgroundTransparency=1
  t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h)
  t.Font=Enum.Font.GothamBlack; t.TextSize=size; t.TextColor3=Color3.fromRGB(246,246,255); t.Text=value
  t.ZIndex=4; return t
 end
 local function allowed()
  return state and (player:GetAttribute("MatchVariant")=="Arcade" or player:GetAttribute("MatchVariant")=="Chaos") and (player:GetAttribute("CourtSide") or 0)~=0
   and not player:GetAttribute("PowerupDraftOpen") and not player:GetAttribute("PracticePaused")
   and not player:GetAttribute("HowToPlayOpen") and not player:GetAttribute("LeaveConfirmationOpen")
   and not player:GetAttribute("PracticeMenuOpen") and not player:GetAttribute("MatchIntroOpen")
 end
 eventTitle=label(chaosBanner,"Title","",12,9,296,22,17)
 eventTitle.TextColor3=Color3.fromRGB(255,160,102)
 eventDetail=label(chaosBanner,"Detail","",12,34,296,18,12)
 eventDetail.Font=Enum.Font.GothamMedium
 local bannerScale=Instance.new("UIScale",chaosBanner)
 local function activate(index) if allowed() and player:GetAttribute("MatchVariant")=="Arcade" then remote:FireServer(index) end end
 for index,key in ipairs({"Q","E"}) do
  local button=Instance.new("TextButton",root); button.Name="Slot"..key; button.Text=""; button.BackgroundTransparency=1
  button.Position=UDim2.fromOffset((index-1)*156,0); button.Size=UDim2.fromOffset(140,158); button.AutoButtonColor=false
  local content=Instance.new("Frame",button); content.Name="Content"; content.Size=UDim2.fromOffset(110,124); content.BackgroundTransparency=1
  local scale=Instance.new("UIScale",content); scale.Scale=140/110
  local frame=Assets.image(content,"slotReady",0,0,110,124); frame.Name="SlotFrame"
  local icon=Instance.new("ImageLabel",content); icon.Name="PowerupIcon"; icon.BackgroundTransparency=1; icon.ScaleType=Enum.ScaleType.Fit; icon.ZIndex=3
  local timer=label(content,"Timer","",67,64,27,13,10)
  local count=label(content,"Charges","",72,20,25,16,11)
  label(content,"Key",key,44,79,22,18,17)
  local status=label(content,"Status","EMPTY",13,97,84,16,11)
  local segments={}
  for i=1,48 do
   local angle=(i-1)/48*math.pi*2-math.pi/2
   local segment=Instance.new("Frame",content); segment.Name="Progress"..i; segment.AnchorPoint=Vector2.new(0.5,0.5)
   segment.Position=UDim2.fromOffset(55+math.cos(angle)*29.8,51.4+math.sin(angle)*29.8)
   segment.Size=UDim2.fromOffset(4.5,7); segment.Rotation=angle*180/math.pi+90; segment.BorderSizePixel=0; segment.ZIndex=2
   local corner=Instance.new("UICorner",segment); corner.CornerRadius=UDim.new(1,0); segments[i]=segment
  end
  buttons[index]={button=button,frame=frame,icon=icon,timer=timer,status=status,count=count,segments=segments}
  button.Activated:Connect(function() activate(index) end)
 end
 network:WaitForChild("State").OnClientEvent:Connect(function(data) state=data.arcade; received=os.clock() end)
 UIS.InputBegan:Connect(function(input,processed)
  if processed or UIS:GetFocusedTextBox() then return end
  if input.KeyCode==Enum.KeyCode.Q then activate(1) elseif input.KeyCode==Enum.KeyCode.E then activate(2) end
 end)
 RunService.RenderStepped:Connect(function()
  if not stamina or not stamina.Parent then
   local hud=player.PlayerGui:FindFirstChild("FigmaHUD"); stamina=hud and hud:FindFirstChild("Stamina")
   if stamina then root.Parent=stamina end
  end
  root.Visible=state~=nil and player:GetAttribute("MatchVariant")=="Arcade"
  local age=player:GetAttribute("PracticePaused") and 0 or os.clock()-received
  local event=state and state.chaos
  local remaining=event and math.max(0,event.remaining-age) or 0
  chaosBanner.Visible=remaining>0 and allowed() and player:GetAttribute("MatchVariant")=="Chaos"
  if event then
   eventTitle.Text=event.name.."  /  "..math.ceil(remaining).."s"
   eventDetail.Text=event.detail
  end
  local camera=workspace.CurrentCamera
  if camera then bannerScale.Scale=math.min(1,(camera.ViewportSize.X-32)/320) end
  glow.Enabled=state~=nil and state.glow==true
  local ball=workspace:FindFirstChild("LocalPickleball")
  if ball and (not lamp or lamp.Parent~=ball) then
   if lamp then lamp:Destroy() end
   lamp=Instance.new("PointLight",ball); lamp.Name="ArcadeBallLight"; lamp.Color=Color3.fromRGB(157,229,255); lamp.Range=14; lamp.Brightness=3
  end
  if lamp then
   lamp.Enabled=glow.Enabled
   lamp.Range=state and state.lightRange or 14
   lamp.Brightness=state and state.lightBrightness or 3
  end
  if not state then return end
  for index,view in ipairs(buttons) do
   local slot=state.slots[index] or {id=""}; local card=Deck.find(slot.id)
   local active=math.max(0,(slot.active or 0)-age); local cooldown=math.max(0,(slot.cooldown or 0)-age)
   local mode=active>0 and "ACTIVE" or cooldown>0 and "COOLDOWN" or slot.armed and "ARMED" or card and "READY" or "EMPTY"
   view.count.Text=(slot.charges or 0)>1 and ("x"..slot.charges) or ""
   view.status.Text=mode; view.frame.Image=Assets.get((mode=="ACTIVE" or mode=="ARMED") and "slotActive" or mode=="COOLDOWN" and "slotCooldown" or "slotReady")
   view.status.TextColor3=mode=="ARMED" and Color3.fromRGB(80,232,255) or Color3.fromRGB(246,246,255)
   view.frame.ImageTransparency=card and 0 or 0.5
   view.icon.Image=card and Assets.get(card.art) or ""; view.icon.ImageTransparency=mode=="COOLDOWN" and 0.4 or 0
   local timed=active>0 or cooldown>0
   view.icon.Position=UDim2.fromOffset(timed and 33 or 22,timed and 30 or 18)
   view.icon.Size=UDim2.fromOffset(timed and 44 or 66,timed and 44 or 66)
   view.timer.Text=timed and tostring(math.ceil(active>0 and active or cooldown)).."s" or ""
   local fraction=active>0 and active/math.max(1,slot.duration) or cooldown/(slot.cooldownDuration or Deck.COOLDOWN)
   for i,segment in ipairs(view.segments) do
    segment.Visible=timed; segment.BackgroundColor3=mode=="ACTIVE" and Color3.fromRGB(255,85,200) or Color3.fromRGB(85,255,213)
    segment.BackgroundTransparency=i/48<=fraction and 0 or 0.8
   end
  end
 end)
end
return Slots
