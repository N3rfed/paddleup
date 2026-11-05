from pathlib import Path
p=Path('src/client/PowerupDraft.luau');s=p.read_text();s=s.replace(' text(panel,"A U G M E N T   D R A F T",',' local eyebrow=text(panel,"A U G M E N T   D R A F T",').replace(' text(panel,"SHARED RARITY  /  PERSONAL OFFERS  /  MATCH-LONG EFFECTS",',' local hint=text(panel,"SHARED RARITY  /  PERSONAL OFFERS  /  MATCH-LONG EFFECTS",')
a='  for index,card in ipairs(data.cards) do\n   local b=Instance.new';assert a in s
branch='''  local arcade=data.mode=="Arcade"
  panel.Size=UDim2.fromOffset(arcade and 1100 or 940,arcade and 620 or 560)
  cards.Size=UDim2.fromOffset(arcade and 1060 or 908,arcade and 410 or 362)
  footer.Position=UDim2.new(0,16,0,arcade and 552 or 508)
  hint.Position=UDim2.new(0,16,0,arcade and 590 or 540)
  eyebrow.Text=arcade and "Y O U R   D E C K" or "A U G M E N T   D R A F T"
  hint.Text=arcade and "CHOOSE A CARD  /  EQUIP A FREE SLOT  /  ACTIVATE WITH Q OR E" or "SHARED RARITY  /  PERSONAL OFFERS  /  MATCH-LONG EFFECTS"
  if arcade then
   title.Text="CHOOSE A POWERUP"
   subtitle.Text="Choose one card for your Q / E slots"; subtitle.TextColor3=Color3.fromRGB(181,187,225)
   for index,card in ipairs(data.cards) do
    local b=Instance.new("TextButton",cards); buttons[index]=b; b.Name="Powerup"..index
    b.Position=UDim2.fromOffset((index-1)*360,0); b.Size=UDim2.fromOffset(340,340*622/569)
    b.BackgroundTransparency=1; b.Text=""; b.AutoButtonColor=false
    local content=Instance.new("Frame",b); content.Name="Content"; content.Size=UDim2.fromOffset(569,622); content.BackgroundTransparency=1
    local contentScale=Instance.new("UIScale",content); contentScale.Scale=340/569
    FigmaAssets.card(content,569)
    local icon=FigmaAssets.image(content,card.art,144,55,280,280); if icon then icon.ScaleType=Enum.ScaleType.Fit end
    local name=text(content,card.name:upper(),350,84,46,Color3.fromRGB(246,246,255)); name.Font=Enum.Font.GothamBlack
    local description=text(content,card.blurb,445,46,34,Color3.fromRGB(202,215,232)); description.TextWrapped=false
    local action=text(content,"SELECT",510,74,30,Color3.fromRGB(246,246,255)); action.Name="CardAction"
    b.Activated:Connect(function() choose(index) end)
   end
   if UIS.GamepadEnabled then GuiService.SelectedObject=buttons[1] end
   return
  end
'''
s=s.replace(a,branch+a,1).replace('footer.Text="Upgrade locked in. Waiting for the other players..."','footer.Text=data.mode=="Arcade" and ("Equipped in "..(data.slot==1 and "Q" or "E")..". Waiting for the other players...") or "Upgrade locked in. Waiting for the other players..."').replace('b:FindFirstChild("SelectedArt")','b:FindFirstChild("SelectedArt",true)')
s=s.replace('(camera.ViewportSize.X-24)/940,(camera.ViewportSize.Y-32)/560','(camera.ViewportSize.X-24)/panel.Size.X.Offset,(camera.ViewportSize.Y-32)/panel.Size.Y.Offset');p.write_text(s)
p=Path('src/client/PowerupBuild.luau');s=p.read_text().replace('elseif data.kind=="chosen" and data.card then','elseif data.kind=="chosen" and data.card and data.mode~="Arcade" then');p.write_text(s)
