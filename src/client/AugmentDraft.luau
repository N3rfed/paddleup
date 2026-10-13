local AugmentDraft={}
function AugmentDraft.start(player,network)
 local TweenService=game:GetService("TweenService")
 local RunService=game:GetService("RunService")
 local UIS=game:GetService("UserInputService")
 local GuiService=game:GetService("GuiService")
 local remote=network:WaitForChild("Augment")
 local colors={Color3.fromRGB(104,239,159),Color3.fromRGB(255,211,93),Color3.fromRGB(255,91,109)}
 local names={"GREEN / UNCOMMON","YELLOW / RARE","RED / MYTHIC"}
 local gui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
 gui.Name="AugmentDraft"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=15
 local function frame(parent,size,position,color)
  local f=Instance.new("Frame",parent); f.Size=size; f.Position=position
  f.BackgroundColor3=color; f.BorderSizePixel=0; return f
 end
 local function round(parent,radius)
  local c=Instance.new("UICorner",parent); c.CornerRadius=UDim.new(0,radius)
 end
 local function stroke(parent,color,width,transparency)
  local s=Instance.new("UIStroke",parent); s.Color=color; s.Thickness=width; s.Transparency=transparency or 0; return s
 end
 local function text(parent,value,y,height,size,color)
  local t=Instance.new("TextLabel",parent); t.BackgroundTransparency=1
  t.Position=UDim2.new(0,16,0,y); t.Size=UDim2.new(1,-32,0,height)
  t.Font=Enum.Font.GothamBold; t.TextSize=size; t.TextColor3=color
  t.Text=value; t.TextWrapped=true; return t
 end
 local overlay=Instance.new("TextButton",gui)
 overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.fromRGB(4,9,17)
 overlay.BackgroundTransparency=0.12; overlay.Text=""; overlay.AutoButtonColor=false
 overlay.Modal=true; overlay.Selectable=false; overlay.Visible=false
 local panel=frame(overlay,UDim2.fromOffset(940,560),UDim2.fromScale(0.5,0.5),Color3.new())
 panel.AnchorPoint=Vector2.new(0.5,0.5); panel.BackgroundTransparency=1
 local scale=Instance.new("UIScale",panel)
 text(panel,"A U G M E N T   D R A F T",0,25,12,Color3.fromRGB(170,186,210))
 local title=text(panel,"CHOOSE YOUR EDGE",32,48,34,Color3.fromRGB(246,247,255))
 local subtitle=text(panel,"One upgrade. Yours for the match.",83,30,14,Color3.fromRGB(170,186,210))
 local cards=frame(panel,UDim2.fromOffset(908,362),UDim2.fromOffset(16,132),Color3.new())
 cards.BackgroundTransparency=1
 local footer=text(panel,"",508,24,14,Color3.fromRGB(226,232,245))
 text(panel,"SHARED RARITY  /  PERSONAL OFFERS  /  STACKING UPGRADES",540,18,10,Color3.fromRGB(126,145,173))
 local build=text(gui,"",112,38,12,Color3.fromRGB(211,224,240)); build.Visible=false
 build.Size=UDim2.fromOffset(540,38); build.Position=UDim2.new(0.5,-270,0,112)
 build.TextStrokeTransparency=0.35
 local active=nil
 local selected=false
 local animations={}
 local buttons={}
 local previousSelection=nil
 local function choose(index)
  if not active or selected or player:GetAttribute("LeaveConfirmationOpen") or not active.cards[index] then return end
  selected=true
  footer.Text="Confirming selection..."
  remote:FireServer(active.id,active.cards[index].id)
 end
 local function close()
  overlay.Visible=false; active=nil; selected=false
  if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(cards) then
   GuiService.SelectedObject=previousSelection and previousSelection.Parent and previousSelection or nil
  end
 end
 local function show(data)
  close(); cards:ClearAllChildren(); table.clear(animations); table.clear(buttons)
  active=data; overlay.Visible=true
  previousSelection=GuiService.SelectedObject
  local color=colors[data.tier]
  title.Text="CHOOSE YOUR EDGE"; title.TextColor3=Color3.fromRGB(246,247,255)
  subtitle.Text=names[data.tier].."  /  Choose one upgrade to keep this match"
  subtitle.TextColor3=color
  for index,card in ipairs(data.cards) do
   local b=Instance.new("TextButton",cards); buttons[index]=b
   b.Name="Augment"..index; b.Position=UDim2.fromOffset((index-1)*308,0)
   b.Size=UDim2.fromOffset(292,362); b.BackgroundColor3=Color3.fromRGB(20,29,44)
   b.Text=""; b.AutoButtonColor=false; round(b,16)
   local border=stroke(b,color,data.tier==3 and 2.5 or 1.5,0.25)
   local gradient=Instance.new("UIGradient",b)
   gradient.Color=ColorSequence.new(Color3.fromRGB(36,48,64):Lerp(color,0.16),Color3.fromRGB(10,15,25)); gradient.Rotation=65
   text(b,string.format("0%d   /   %s",index,names[data.tier]),15,22,10,color)
   local art=frame(b,UDim2.fromOffset(126,126),UDim2.fromOffset(83,55),color)
   art.BackgroundTransparency=1
   -- Rarity adds concentric seals, facets, corner inlays and orbiting gems.
   for layer=1,data.tier do
    local ring=frame(art,UDim2.fromOffset(66+layer*17,66+layer*17),UDim2.fromScale(0.5,0.5),color)
    ring.AnchorPoint=Vector2.new(0.5,0.5); ring.BackgroundTransparency=1
    ring.Rotation=45; round(ring,layer==1 and 16 or 4)
    stroke(ring,color,layer==1 and 2 or 1,0.15+layer*0.16)
    table.insert(animations,{object=ring,speed=(layer%2==0 and -1 or 1)*(data.tier==3 and 12 or 4)})
   end
   local emblem=text(art,card.symbol=="WIND" and ">>" or card.symbol=="PULSE" and "+" or card.symbol=="ORBIT" and "O" or "V",38,48,38,color)
   emblem.Rotation=card.symbol=="SHIELD" and 180 or 0
   for gem=1,data.tier*4 do
    local angle=gem/(data.tier*4)*math.pi*2
    local dot=frame(art,UDim2.fromOffset(data.tier+2,data.tier+2),UDim2.fromOffset(63+math.cos(angle)*62,63+math.sin(angle)*62),color)
    dot.AnchorPoint=Vector2.new(0.5,0.5); dot.Rotation=45
   end
   if data.tier>=2 then
    for _,x in ipairs({12,272}) do
     for _,y in ipairs({45,277}) do
      local jewel=frame(b,UDim2.fromOffset(7,7),UDim2.fromOffset(x,y),color); jewel.Rotation=45
      if data.tier==3 then
       local inlay=frame(b,UDim2.fromOffset(2,45),UDim2.fromOffset(x+2,y==45 and 61 or 218),color)
       inlay.BackgroundTransparency=0.45
      end
     end
    end
   end
   text(b,card.name:upper(),196,32,21,Color3.fromRGB(246,247,255))
   local desc=text(b,card.description,236,44,15,Color3.fromRGB(202,215,232)); desc.Font=Enum.Font.GothamMedium
   local pill=frame(b,UDim2.new(1,-36,0,42),UDim2.fromOffset(18,300),color); round(pill,9)
   text(pill,"["..index.."]  SELECT AUGMENT",0,42,12,Color3.fromRGB(15,22,31))
   local function hover(on)
    TweenService:Create(border,TweenInfo.new(0.15),{Transparency=on and 0 or 0.25,Thickness=on and 3 or (data.tier==3 and 2.5 or 1.5)}):Play()
   end
   b.MouseEnter:Connect(function() hover(true) end); b.MouseLeave:Connect(function() hover(false) end)
   b.SelectionGained:Connect(function() hover(true) end); b.SelectionLost:Connect(function() hover(false) end)
   b.Activated:Connect(function() choose(index) end)
  end
  if UIS.GamepadEnabled then GuiService.SelectedObject=buttons[1] end
 end
 remote.OnClientEvent:Connect(function(data)
  if data.kind=="offer" then show(data)
  elseif data.kind=="chosen" then
   selected=true; title.Text=data.name:upper().." ACQUIRED"
   footer.Text="Upgrade locked in. Waiting for the other players..."
   for index,b in ipairs(buttons) do
    b.Active=false
    if active and active.cards[index].name~=data.name then b.BackgroundTransparency=0.6 end
   end
   local stats=data.stats
   build.Text=string.format("%d AUGMENTS  /  MOVE +%d%%  /  REGEN +%d%%  /  REACH +%d%%  /  DIVE -%d%%",data.count,
    math.floor((stats.speed or 0)*100+0.5),math.floor((stats.regen or 0)*100+0.5),math.floor((stats.reach or 0)*100+0.5),math.floor((stats.dive or 0)*100+0.5))
  elseif data.kind=="close" then close()
  elseif data.kind=="reset" then close(); build.Text="" end
 end)
 UIS.InputBegan:Connect(function(input,processed)
  if processed or UIS:GetFocusedTextBox() or player:GetAttribute("LeaveConfirmationOpen") then return end
  local index=({[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3})[input.KeyCode]
  if index then choose(index) end
 end)
 RunService.RenderStepped:Connect(function(dt)
  local camera=workspace.CurrentCamera
  if camera then
   scale.Scale=math.max(0.1,math.min(1,(camera.ViewportSize.X-24)/940,(camera.ViewportSize.Y-32)/560))
   build.Size=UDim2.fromOffset(math.min(540,camera.ViewportSize.X-24),38)
   build.Position=UDim2.new(0.5,-build.Size.X.Offset/2,0,112)
  end
  build.Visible=player:GetAttribute("MatchVariant")=="Augmented" and not overlay.Visible and build.Text~=""
  if not overlay.Visible then return end
  for _,animation in ipairs(animations) do animation.object.Rotation+=dt*animation.speed end
  if active and not selected then
   footer.Text=string.format("%ds TO CHOOSE  /  First card auto-selects on timeout",math.max(0,math.ceil(active.endsAt-workspace:GetServerTimeNow())))
  end
 end)
end
return AugmentDraft
