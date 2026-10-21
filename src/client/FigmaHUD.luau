local Assets = require(script.Parent:WaitForChild("FigmaAssets"))
local HUD = {}
function HUD.start(player, network, legacyScore, legacyStamina)
 -- Background exports contain no live names, scores, or stamina fill.
 for _,name in ipairs({"score","stamina"}) do
  if not Assets.get(name) then return end
 end
 local Players = game:GetService("Players")
 local gui = Instance.new("ScreenGui")
 gui.Name="FigmaHUD"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=2
 gui.Parent=player:WaitForChild("PlayerGui")
 local function frame(parent,name,width,height)
  local f=Instance.new("Frame"); f.Name=name; f.Size=UDim2.fromOffset(width,height)
  f.BackgroundTransparency=1; f.Parent=parent; return f
 end
 local function label(parent,name,value,x,y,w,h,size)
  local t=Instance.new("TextLabel"); t.Name=name; t.Text=value
  t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h)
  t.BackgroundTransparency=1; t.TextColor3=Color3.fromRGB(246,246,255)
  t.Font=Enum.Font.GothamBold; t.TextSize=size; t.TextTruncate=Enum.TextTruncate.AtEnd
  t.ZIndex=3; t.Parent=parent; return t
 end
 local score=frame(gui,"Scoreboard",892,173)
 score.AnchorPoint=Vector2.new(0.5,0); score.Position=UDim2.new(0.5,0,0,18)
 local scoreScale=Instance.new("UIScale",score)
 local scoreArt=Assets.image(score,"score",0,0,892,150.5)
 scoreArt.ScaleType=Enum.ScaleType.Fit
 local home=label(score,"Home","WAITING…",0,0,225,41,30)
 local away=label(score,"Away","WAITING…",0,0,225,41,30)
 -- Centers measured from the colored panels in the 892 × 150.5 background.
 home.AnchorPoint=Vector2.new(0.5,0.5); home.Position=UDim2.fromOffset(166,60)
 away.AnchorPoint=Vector2.new(0.5,0.5); away.Position=UDim2.fromOffset(726,60)
 home.TextXAlignment=Enum.TextXAlignment.Center; home.TextYAlignment=Enum.TextYAlignment.Center
 away.TextXAlignment=Enum.TextXAlignment.Center; away.TextYAlignment=Enum.TextYAlignment.Center
 local left=label(score,"HomeScore","0",0,0,64,70,58)
 local right=label(score,"AwayScore","0",0,0,64,70,58)
 -- Keep both scores symmetric about the artwork separator at (448, 57.5).
 left.AnchorPoint=Vector2.new(0.5,0.5); left.Position=UDim2.fromOffset(390,57.5)
 right.AnchorPoint=Vector2.new(0.5,0.5); right.Position=UDim2.fromOffset(506,57.5)
 left.TextXAlignment=Enum.TextXAlignment.Center; left.TextYAlignment=Enum.TextYAlignment.Center
 right.TextXAlignment=Enum.TextXAlignment.Center; right.TextYAlignment=Enum.TextYAlignment.Center
 left.Font=Enum.Font.GothamBlack; right.Font=Enum.Font.GothamBlack
 -- The separator is part of the scoreboard background.
 -- The server has no round counter: show its actual team format instead.
 local format=label(score,"Format","PRACTICE",0,0,211,44,32)
 format.AnchorPoint=Vector2.new(0.5,0.5); format.Position=UDim2.fromOffset(448,123)
 format.TextXAlignment=Enum.TextXAlignment.Center; format.TextYAlignment=Enum.TextYAlignment.Center
 local serving=frame(score,"Serving",213,51)
 serving.AnchorPoint=Vector2.new(0.5,0)
 serving.Position=UDim2.fromOffset(166,86)
 serving.Visible=false
 local servingHome=Assets.image(serving,"servePink",0,0,213,51)
 local servingAway=Assets.image(serving,"serveCyan",0,0,213,51)
 local serveText=label(serving,"Server","SERVING · 1",12,6.5,189,38,20)
 serveText.Font=Enum.Font.GothamMedium
 local serveCountdown=frame(gui,"ServeCountdown",240,56)
 serveCountdown.AnchorPoint=Vector2.new(0.5,0); serveCountdown.Visible=false
 serveCountdown.BackgroundTransparency=0; serveCountdown.BackgroundColor3=Color3.fromRGB(27,27,64)
 local timerCorner=Instance.new("UICorner",serveCountdown); timerCorner.CornerRadius=UDim.new(0,7)
 local timerBorder=Instance.new("UIStroke",serveCountdown); timerBorder.Color=Color3.fromRGB(80,232,255); timerBorder.Thickness=2
 timerBorder.Transparency=0.15
 local timerScale=Instance.new("UIScale",serveCountdown)
 local timerText=label(serveCountdown,"Timer","",8,8,224,40,26)
 timerText.TextColor3=Color3.fromRGB(80,232,255); timerText.Font=Enum.Font.GothamBold
 local stamina=frame(gui,"Stamina",523,120)
 stamina.AnchorPoint=Vector2.new(0.5,1); stamina.Position=UDim2.new(0.5,0,1,-24)
 local staminaScale=Instance.new("UIScale",stamina)
 Assets.image(stamina,"stamina",0,0,523,87)
 local status=label(stamina,"Status","STAMINA",27,13,468,25,18)
 status.TextXAlignment=Enum.TextXAlignment.Left
 local track=frame(stamina,"Track",468,18); track.Position=UDim2.fromOffset(27,47)
 track.BackgroundColor3=Color3.fromRGB(55,54,95); track.BackgroundTransparency=0
 local c=Instance.new("UICorner",track); c.CornerRadius=UDim.new(1,0)
 local fill=frame(track,"Fill",468,18); fill.BackgroundColor3=Color3.fromRGB(80,232,255); fill.BackgroundTransparency=0
 local fc=Instance.new("UICorner",fill); fc.CornerRadius=UDim.new(1,0)
 local dive=label(stamina,"Dive","DIVE READY",27,91,468,22,16)
 local introducing=false
 local function visibility()
  local mode=player:GetAttribute("SessionMode")
  gui.Enabled=mode~=nil and mode~="Lobby" and not introducing and not player:GetAttribute("PowerupDraftOpen")
  legacyScore.Visible=false; legacyStamina.Visible=false
 end
 player:GetAttributeChangedSignal("SessionMode"):Connect(visibility)
 player:GetAttributeChangedSignal("PowerupDraftOpen"):Connect(visibility)
 -- The developer toggle may request the original panels again.
 legacyScore:GetPropertyChangedSignal("Visible"):Connect(function()
  if legacyScore.Visible then legacyScore.Visible=false end
 end)
 legacyStamina:GetPropertyChangedSignal("Visible"):Connect(function()
  if legacyStamina.Visible then legacyStamina.Visible=false end
 end)
 local function teamName(side)
  local names={}
  for _,p in ipairs(Players:GetPlayers()) do
   if p:GetAttribute("CourtSide")==side then table.insert(names,p.DisplayName) end
  end
  table.sort(names)
  if #names==0 then return side==-1 and player:GetAttribute("SessionMode")=="Practice" and "PRACTICE BOT" or "WAITING…" end
  return table.concat(names," / ")
 end
 -- A compact burst follows only the score number that increased.
 local TweenService=game:GetService("TweenService")
 local Debris=game:GetService("Debris")
 local random=Random.new()
 local particles=frame(score,"ScoreParticles",892,173)
 particles.ZIndex=5
 local function celebrate(side)
  if not gui.Enabled then return end
  local teamColor=side==1 and Color3.fromRGB(255,85,200) or Color3.fromRGB(80,232,255)
  local target=side==1 and left or right
  local center=target.Position
  for i=1,24 do
   local p=Instance.new("Frame")
   p.Name="Confetti"; p.AnchorPoint=Vector2.new(0.5,0.5)
   local angle=random:NextNumber(0,math.pi*2)
   local radius=random:NextNumber(42,76)
   p.Position=UDim2.fromOffset(center.X.Offset+math.cos(angle)*16,center.Y.Offset+math.sin(angle)*18)
   local size=random:NextInteger(3,6)
   p.Size=UDim2.fromOffset(size,random:NextInteger(3,6))
   p.BorderSizePixel=0; p.BackgroundColor3=i%5==0 and Color3.fromRGB(255,240,170) or i%3==0 and Color3.new(1,1,1) or teamColor
   p.Rotation=random:NextInteger(-180,180); p.ZIndex=5; p.Parent=particles
   local duration=random:NextNumber(0.5,0.8)
   TweenService:Create(p,TweenInfo.new(duration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
    Position=UDim2.fromOffset(center.X.Offset+math.cos(angle)*radius,center.Y.Offset+math.sin(angle)*radius*0.65),
    Rotation=p.Rotation+random:NextInteger(-240,240), BackgroundTransparency=1,
   }):Play()
   Debris:AddItem(p,duration+0.1)
  end
 end
 local previousScore=nil
 player:GetAttributeChangedSignal("SessionMode"):Connect(function()
  previousScore=nil
  particles:ClearAllChildren()
 end)
 local readyAt=0
 local serveState
 network:WaitForChild("State").OnClientEvent:Connect(function(data)
  serveState=data
  local introVisible=data.matchIntro~=nil
  if introducing~=introVisible then introducing=introVisible; visibility() end
  local currentHome,currentAway=data.score[1],data.score[2]
  -- First snapshots and score resets establish a baseline without a celebration.
  if previousScore then
   if currentHome==previousScore[1]+1 and currentAway==previousScore[2] then celebrate(1)
   elseif currentAway==previousScore[2]+1 and currentHome==previousScore[1] then celebrate(-1) end
  end
  previousScore={currentHome,currentAway}
  left.Text=tostring(currentHome); right.Text=tostring(currentAway)
  home.Text=teamName(1); away.Text=teamName(-1)
  local mode=player:GetAttribute("SessionMode") or "MATCH"
  local homeCount,awayCount=mode:match("^(%d+)[vV](%d+)$")
  format.Text=homeCount and (homeCount.." v "..awayCount) or string.upper(mode)
  -- Tuck the badge under the panel edge, centered on the serving team.
  serving.Position=UDim2.fromOffset(data.servingSide==1 and 166 or 726,86)
  if servingHome then servingHome.Visible=data.servingSide==1 end
  if servingAway then servingAway.Visible=data.servingSide~=1 end
  serving.Visible=not data.live
  serveText.Text="SERVING · "..tostring(data.serverNumber or 1)
  fill.Size=UDim2.fromScale(math.clamp(data.stamina/100,0,1),1)
  status.Text=data.comeback and "COMEBACK / +15% MOVE + HIT" or data.powerupStatus and data.powerupStatus~="" and data.powerupStatus or "STAMINA"
  readyAt=data.diveReadyAt or workspace:GetServerTimeNow()+(data.dive or 0)
 end)
 game:GetService("RunService").RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera then
   local s=math.min(1,camera.ViewportSize.X/1920,camera.ViewportSize.Y/1080)
   -- Keep the score about 20% smaller on desktop, with room for corner controls
   -- on narrow screens and a height limit that preserves the view of high balls.
   scoreScale.Scale=math.max(0.01,math.min(0.88,(camera.ViewportSize.X-128)/892,camera.ViewportSize.Y*0.14/173))
   score.Position=UDim2.new(0.5,0,0,math.clamp(camera.ViewportSize.Y/60,8,18))
   timerScale.Scale=math.min(1,math.max(0.5,(camera.ViewportSize.X-48)/240))
   serveCountdown.Position=UDim2.new(0.5,0,0,score.Position.Y.Offset+173*scoreScale.Scale+6)
   staminaScale.Scale=s*1.15
  end
  local data=serveState
  if data then
   local countdown=data.canServe and data.serverId==player.UserId and data.serveReady
    and not data.live and not data.practicePaused and data.serveDeadline
    and not data.matchIntro and not player:GetAttribute("PowerupDraftOpen")
    and not player:GetAttribute("PracticeMenuOpen") and not player:GetAttribute("LeaveConfirmationOpen")
   serveCountdown.Visible=countdown~=nil and countdown~=false
   if countdown then
    local seconds=math.ceil(math.max(0,data.serveDeadline-workspace:GetServerTimeNow()))
    timerText.Text="SERVE IN "..seconds.."s"
    local accent=seconds<=3 and Color3.fromRGB(255,85,200) or Color3.fromRGB(80,232,255)
    timerText.TextColor3=accent; timerBorder.Color=accent
   end
  end
  local remaining=math.max(0,readyAt-workspace:GetServerTimeNow())
  dive.Text=remaining>0 and string.format("DIVE  %.1fs",remaining) or "DIVE READY"
 end)
 visibility()
end
return HUD
