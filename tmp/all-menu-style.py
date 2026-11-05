from pathlib import Path
p=Path('src/client/FigmaAssets.luau');s=p.read_text().replace('Assets.ids = {','Assets.ids = {\n panelCyan="rbxassetid://104916959855150",panelPurple="rbxassetid://111939750083442",panelPink="rbxassetid://89765864347064",');p.write_text(s)
p=Path('src/client/MainMenuFlow.luau');s=p.read_text()
a=' local function button(name,title,description,y,action,enabled,accent,height)'
helper=''' local function neon(parent,accent)
  local key=accent==pink and "panelPink" or accent==Color3.fromRGB(169,151,255) and "panelPurple" or "panelCyan"
  local skin=Assets.image(parent,key,-10,-10,1,1)
  skin.Name="NeonFrame"; skin.Size=UDim2.new(1,20,1,20)
  skin.ScaleType=Enum.ScaleType.Slice; skin.SliceCenter=Rect.new(48,48,208,208); skin.SliceScale=0.5
  skin.ImageTransparency=0.12; skin.ZIndex=1
  return skin
 end
'''
assert a in s;s=s.replace(a,helper+a)
s=s.replace('  b.BackgroundColor3=Color3.fromRGB(36,36,77)','  b.BackgroundColor3=Color3.fromRGB(36,36,77); b.BackgroundTransparency=1\n  stroke.Enabled=false; neon(b,accent or cyan)',1)
s=s.replace('label.Font=Enum.Font.GothamBold','label.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Bold)')
s=s.replace('primary.Position=UDim2.fromOffset(72,9); primary.Size=UDim2.new(1,-108,0,22)','primary.Position=UDim2.fromOffset(58,9); primary.Size=UDim2.new(1,-96,0,22); primary.ZIndex=3\n  primary.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)')
s=s.replace('detail.Position=UDim2.fromOffset(72,33); detail.Size=UDim2.new(1,-88,0,18)','detail.Position=UDim2.fromOffset(58,33); detail.Size=UDim2.new(1,-76,0,18); detail.ZIndex=3')
s=s.replace('badge.BackgroundColor3=accent or cyan; badge.BackgroundTransparency=0.9; badge.BorderSizePixel=0','badge.BackgroundColor3=accent or cyan; badge.BackgroundTransparency=1; badge.BorderSizePixel=0; badge.ZIndex=2')
s=s.replace('arrow.Position=UDim2.new(1,-30,0,9);','arrow.ZIndex=3\n  arrow.Position=UDim2.new(1,-30,0,9);')
s=s.replace('   if b:GetAttribute("GameTile") then','   TweenService:Create(b.NeonFrame,TweenInfo.new(0.16),{ImageTransparency=active and 0 or 0.12}):Play()\n   if b:GetAttribute("GameTile") then')
a=s.index('   card.BackgroundTransparency=1; card.Accent.Enabled=false');b=s.index('   art=Instance.new("Frame",card)',a)
s=s[:a]+s[b:]
# Match formats use full-width rows, mirroring the mode screen.
a=s.index('    card.Position=UDim2.fromOffset(24+((index-1)%2)*192');b=s.index('\n   end\n   button("Back"',a)
s=s[:a]+'''    card.Position=UDim2.fromOffset(24,120+(index-1)*92)
    card.Size=UDim2.new(1,-48,0,80)
    card:SetAttribute("GameTile",true); card.ModeIcon.Visible=false; card.Arrow.Visible=false
    card.Title.Position=UDim2.fromOffset(24,12); card.Title.Size=UDim2.fromOffset(196,30); card.Title.TextSize=25
    card.Title.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
    card.Detail.Position=UDim2.fromOffset(24,46); card.Detail.Size=UDim2.fromOffset(196,22); card.Detail.TextSize=13
    if item[1]=="Practice" then
     local icon=Assets.image(card,"paddle",248,-2,100,84); icon.ScaleType=Enum.ScaleType.Fit; icon.ZIndex=2
    else
     local mark=text(card,"MatchFormat",item[1]:gsub("V"," v "),16,46,32,index%2==0 and pink or cyan)
     mark.Position=UDim2.fromOffset(238,16); mark.Size=UDim2.fromOffset(116,46); mark.TextXAlignment=Enum.TextXAlignment.Center; mark.ZIndex=3
     mark.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)
    end'''+s[b:]
s=s.replace('button("Back","BACK","Choose another mode",408,','button("Back","BACK","Choose another mode",488,')
# A matching status card surrounds queue progress.
a='   local count=text(panel,"QueueCount",'
i=s.index(a);s=s[:i]+'''   local queueCard=Instance.new("Frame",panel); queueCard.Name="QueueStatus"; queueCard.BackgroundTransparency=1
   queueCard.Position=UDim2.fromOffset(24,156); queueCard.Size=UDim2.new(1,-48,0,128); neon(queueCard,cyan); table.insert(controls,queueCard)
'''+s[i:]
s=s.replace('local count=text(panel,"QueueCount",','local count=text(queueCard,"QueueCount",').replace(' PLAYERS",190,64,30,cyan)',' PLAYERS",32,64,30,cyan)')
# Keep map imagery inside the same frame, with live votes and selection highlights.
s=s.replace('   card:SetAttribute("Selected",own~=nil and own.map==map)','   card:SetAttribute("Selected",own~=nil and own.map==map)\n   card.NeonFrame.ImageTransparency=own and own.map==map and 0 or 0.25')
s=s.replace('card.Accent.Transparency=map==highlighted and 0 or 0.7','card.Accent.Transparency=map==highlighted and 0 or 0.7\n     card.NeonFrame.ImageTransparency=map==highlighted and 0 or 0.45')
p.write_text(s)
