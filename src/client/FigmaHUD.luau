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
 local function visibility()
  local mode=player:GetAttribute("SessionMode")
  gui.Enabled=mode~=nil and mode~="Lobby"
  legacyScore.Visible=false; legacyStamina.Visible=false
 end
 player:GetAttributeChangedSignal("SessionMode"):Connect(visibility)
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
 network:WaitForChild("State").OnClientEvent:Connect(function(data)
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
  status.Text=data.comeback and "COMEBACK / +15% MOVE + HIT" or data.augmentStatus and data.augmentStatus~="" and data.augmentStatus or "STAMINA"
  readyAt=data.diveReadyAt or workspace:GetServerTimeNow()+(data.dive or 0)
 end)
 game:GetService("RunService").RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera then
   local s=math.min(1,camera.ViewportSize.X/1920,camera.ViewportSize.Y/1080)
   scoreScale.Scale=s*1.10; staminaScale.Scale=s*1.15
  end
  local remaining=math.max(0,readyAt-workspace:GetServerTimeNow())
  dive.Text=remaining>0 and string.format("DIVE  %.1fs",remaining) or "DIVE READY"
 end)
 visibility()
end
return HUD
