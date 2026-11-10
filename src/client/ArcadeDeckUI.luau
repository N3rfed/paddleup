local UI={}
local Assets=require(script.Parent:WaitForChild("FigmaAssets"))
function UI.open(player,onConfirm,onBack,options)
 local Deck=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ArcadeDeck"))
 local gui=Instance.new("ScreenGui")
 gui.Name="ArcadeDeckSelection"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=60
 local background=Instance.new("TextButton",gui)
 background.Size=UDim2.fromScale(1,1); background.BackgroundColor3=Color3.fromRGB(16,19,46)
 background.Text=""; background.AutoButtonColor=false; background.Modal=true; background.Selectable=false
 local canvas=Instance.new("Frame",background)
 canvas.Size=UDim2.fromOffset(1920,1080); canvas.Position=UDim2.fromScale(0.5,0.5)
 canvas.AnchorPoint=Vector2.new(0.5,0.5); canvas.BackgroundTransparency=1
 local scale=Instance.new("UIScale",canvas)
 local pink=Color3.fromRGB(255,85,200)
 local white=Color3.fromRGB(246,246,255)
 local function text(parent,name,value,x,y,w,h,size,color)
  local t=Instance.new("TextLabel",parent); t.Name=name; t.BackgroundTransparency=1
  t.Position=UDim2.fromOffset(x,y); t.Size=UDim2.fromOffset(w,h)
  t.Font=Enum.Font.Nunito; t.TextSize=size; t.TextColor3=color or white; t.Text=value; t.TextWrapped=true
  t.ZIndex=3; return t
 end
 local heading=text(canvas,"Heading","CHOOSE YOUR <font color='#EE80FF'>POWERUPS</font>",300,15,1320,90,76)
 heading.RichText=true; heading.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
 Assets.image(canvas,"deckBoltLeft",270,28,64,77)
 Assets.image(canvas,"deckBoltRight",1586,28,70,77)
 local selected,buttons,lights={},{},{}
 local enter=Instance.new("TextButton",canvas)
 enter.Name="EnterMatch"; enter.Position=UDim2.fromOffset(715,985); enter.Size=UDim2.fromOffset(490,72)
 enter.Text=""; enter.BackgroundTransparency=1; enter.AutoButtonColor=false
 local enterArt=Assets.image(enter,"deckEnter",0,0,490,72)
 local enterLabel=text(enter,"Label",options and "READY   >" or "ENTER MATCH   >",0,0,490,72,32,Color3.fromRGB(10,10,20))
 enterLabel.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
 local function refresh()
  enter.Active=#selected==Deck.SIZE; enter.Selectable=enter.Active
  enterLabel.TextTransparency=enter.Active and 0 or 0.65
  if enterArt then enterArt.ImageTransparency=enter.Active and 0 or 0.65 end
  for index,card in ipairs(Deck.cards) do
   local active=table.find(selected,card.id)~=nil
   buttons[index]:SetAttribute("Selected",active)
   buttons[index].Content:FindFirstChild("SelectedArt").Visible=active
   buttons[index].Content.CardAction.Text=active and "EQUIPPED" or "SELECT"
  end
  for index,dot in ipairs(lights) do dot.BackgroundTransparency=index<=#selected and 0 or 0.8 end
 end
 for index,card in ipairs(Deck.cards) do
  local b=Instance.new("TextButton",canvas); buttons[index]=b
  b.Name=card.id; b.Position=UDim2.fromOffset(188+((index-1)%4)*398,150+math.floor((index-1)/4)*400)
  b.Size=UDim2.fromOffset(350,350*622/569); b.Text=""; b.BackgroundTransparency=1; b.AutoButtonColor=false
  local content=Instance.new("Frame",b); content.Name="Content"
  content.Size=UDim2.fromOffset(569,622); content.BackgroundTransparency=1
  Instance.new("UIScale",content).Scale=350/569
  Assets.card(content,569)
  local icon=Assets.image(content,card.art,144,55,280,280)
  icon.ScaleType=Enum.ScaleType.Fit
  local name=text(content,"Title",string.upper(card.name),36,350,497,84,56)
  name.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
  local blurb=text(content,"Description",card.blurb,36,445,497,46,40)
  blurb.TextWrapped=false; blurb.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Bold)
  local action=text(content,"CardAction","SELECT",40,510,489,74,34)
  action.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
  b.Activated:Connect(function()
   local position=table.find(selected,card.id)
   if position then table.remove(selected,position)
   elseif #selected<Deck.SIZE then table.insert(selected,card.id)
   else return end
   refresh()
  end)
 end
 for index=1,3 do
  local dot=Instance.new("Frame",canvas); lights[index]=dot
  dot.Name="SelectionDot"..index
  dot.Position=UDim2.fromOffset(921+(index-1)*30,115); dot.Size=UDim2.fromOffset(18,18)
  dot.BorderSizePixel=0; dot.BackgroundColor3=pink
  local round=Instance.new("UICorner",dot); round.CornerRadius=UDim.new(1,0)
 end
 local back=Instance.new("TextButton",canvas)
 back.Name="Back"; back.Position=UDim2.fromOffset(48,35); back.Size=UDim2.fromOffset(160,40)
 back.BackgroundTransparency=1; back.Text="<  BACK"; back.TextColor3=white; back.TextSize=24; back.Font=Enum.Font.Nunito
 if options then back.Text="<  LEAVE MATCH"; back.Size=UDim2.fromOffset(220,40) end
 local countdown=options and text(canvas,"Countdown","",1530,100,320,40,22,white)
 local frames=game:GetService("RunService").RenderStepped:Connect(function()
  local camera=workspace.CurrentCamera
  if camera then scale.Scale=math.min(camera.ViewportSize.X/1920,camera.ViewportSize.Y/1080) end
  if countdown then countdown.Text="Auto-pick in "..math.ceil(math.max(0,options.endsAt-workspace:GetServerTimeNow())).."s" end
 end)
 gui.Destroying:Connect(function() frames:Disconnect() end)
 back.Activated:Connect(function() gui:Destroy(); onBack() end)
 enter.Activated:Connect(function()
  local deck=Deck.validate(selected)
  if not deck then return end
  gui:Destroy(); onConfirm(deck)
 end)
 refresh(); gui.Parent=player:WaitForChild("PlayerGui")
 return gui
end
return UI
