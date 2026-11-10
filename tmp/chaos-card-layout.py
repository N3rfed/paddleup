from pathlib import Path
p=Path('src/client/PowerupDraft.luau');s=p.read_text()
a=s.index('  for index,card in ipairs(data.cards) do',s.index('   return\n  end'))
b=s.index('  if UIS.GamepadEnabled then GuiService.SelectedObject=buttons[1] end',a)
new='''  -- Chaos shares the clean three-card artwork while keeping its stacking catalog.
  panel.Size=UDim2.fromOffset(1920,1080)
  cards.Position=UDim2.fromOffset(80,235); cards.Size=UDim2.fromOffset(1760,620)
  eyebrow.Visible=false; title.Visible=false; hint.Visible=false
  subtitle.Position=UDim2.fromOffset(16,175); subtitle.Size=UDim2.new(1,-32,0,34)
  subtitle.Text=names[data.tier].."  /  CHOOSE ONE UPGRADE"; subtitle.TextSize=24
  footer.Position=UDim2.fromOffset(16,900); footer.TextSize=22
  for index,card in ipairs(data.cards) do
   local b=Instance.new("TextButton",cards); buttons[index]=b; b.Name="Powerup"..index
   b.Position=UDim2.fromOffset((index-1)*610,0); b.Size=UDim2.fromOffset(540,540*622/569)
   b.BackgroundTransparency=1; b.Text=""; b.AutoButtonColor=false
   local hoverScale=Instance.new("UIScale",b)
   local content=Instance.new("Frame",b); content.Name="Content"; content.Size=UDim2.fromOffset(569,622); content.BackgroundTransparency=1
   local contentScale=Instance.new("UIScale",content); contentScale.Scale=540/569
   FigmaAssets.card(content,569)
   local art=frame(content,UDim2.fromOffset(126,126),UDim2.fromOffset(144,40),color)
   art.Name="PowerupArt"; art.BackgroundTransparency=1
   local artScale=Instance.new("UIScale",art); artScale.Scale=280/126
   Art.draw(art,card,color)
   local name=text(content,card.name:upper(),330,84,44,Color3.fromRGB(246,247,255)); name.Name="Title"; name.Font=Enum.Font.GothamBlack
   local description=text(content,card.description,420,78,26,Color3.fromRGB(202,215,232)); description.Name="Description"; description.Font=Enum.Font.GothamMedium
   local action=text(content,"SELECT",510,74,30,Color3.fromRGB(246,246,255)); action.Name="CardAction"
   local function hover(on)
    TweenService:Create(hoverScale,TweenInfo.new(0.15),{Scale=on and not selected and 1.015 or 1}):Play()
   end
   b.MouseEnter:Connect(function() hover(true) end); b.MouseLeave:Connect(function() hover(false) end)
   b.SelectionGained:Connect(function() hover(true) end); b.SelectionLost:Connect(function() hover(false) end)
   b.Activated:Connect(function() choose(index) end)
  end
'''
s=s[:a]+new+s[b:]
# Reset geometry/visibility when switching between modes.
s=s.replace('  local arcade=data.mode=="Arcade"','  local arcade=data.mode=="Arcade"\n  eyebrow.Visible=true; title.Visible=true; hint.Visible=true\n  cards.Position=UDim2.fromOffset(16,132)\n  subtitle.Position=UDim2.new(0,16,0,83); subtitle.Size=UDim2.new(1,-32,0,30); subtitle.TextSize=14\n  footer.TextSize=14')
s=s.replace('elseif data.kind=="close" then close()','''elseif data.kind=="close" then
   if selected and active then
    local offer=active
    task.delay(0.5,function() if active==offer then close() end end)
   else close() end''')
# Remove unused ornament helpers and animation collection.
s=s.replace(' local animations={}\n','').replace('table.clear(animations); ','')
a=s.index(' local function round(');b=s.index(' local function text(',a);s=s[:a]+s[b:]
s=s.replace('RunService.RenderStepped:Connect(function(dt)','RunService.RenderStepped:Connect(function()')
a=s.index('  for _,animation in ipairs(animations) do');b=s.index('  if active and not selected then',a);s=s[:a]+s[b:]
p.write_text(s)
p=Path('src/client/FigmaHUD.luau');s=p.read_text();a='  gui.Enabled=mode~=nil and mode~="Lobby" and not introducing and not player:GetAttribute("PowerupDraftOpen")';assert a in s;s=s.replace(a,'''  local draft=player:GetAttribute("PowerupDraftOpen")==true
  local chaosDraft=draft and player:GetAttribute("MatchVariant")=="Chaos"
  gui.DisplayOrder=chaosDraft and 72 or 2
  gui.Enabled=mode~=nil and mode~="Lobby" and not introducing and (not draft or chaosDraft)''');p.write_text(s)
