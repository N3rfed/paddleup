from pathlib import Path
p=Path('src/client/PracticeUI.luau');s=p.read_text()
s=s.replace('toolbar.Size=UDim2.fromOffset(144,102)','toolbar.Size=UDim2.fromOffset(214,50)')
s=s.replace('b.TextSize=14','b.TextSize=12')
s=s.replace('"Mode: Normal",UDim2.fromOffset(0,0),UDim2.fromOffset(144,34)','"NORMAL  v",UDim2.fromOffset(0,0),UDim2.fromOffset(126,34)')
s=s.replace('"Pause",UDim2.fromOffset(0,42),UDim2.fromOffset(144,34)','"PAUSE",UDim2.fromOffset(134,0),UDim2.fromOffset(80,34)')
s=s.replace('help.Position=UDim2.fromOffset(0,82); help.Size=UDim2.fromOffset(144,18)','help.Position=UDim2.fromOffset(0,38); help.Size=UDim2.fromOffset(214,12)\n help.TextXAlignment=Enum.TextXAlignment.Right; help.TextTransparency=0.25')
s=s.replace('menu.Position=UDim2.fromOffset(0,40); menu.Size=UDim2.fromOffset(144,114)','menu.Position=UDim2.fromOffset(0,-122); menu.Size=UDim2.fromOffset(126,114)')
s=s.replace('  pause.Position=UDim2.fromOffset(0,open and 162 or 42)','  help.Visible=not open and UIS.KeyboardEnabled')
s=s.replace('UDim2.fromOffset(132,32)','UDim2.fromOffset(114,32)')
s=s.replace('mode.Text="Mode: "..name','mode.Text=string.upper(name).."  v"').replace('mode.Text="Mode: "..difficulty','mode.Text=string.upper(difficulty).."  v"')
s=s.replace('pause.Text=latest.paused and "Continue" or "Pause"','pause.Text=latest.paused and "CONTINUE" or "PAUSE"')
a=s.index('  scale.Scale=math.clamp(viewport.X/1500,0.8,1)');b=s.index('\n end)\n visibility()',a)
s=s[:a]+'''  scale.Scale=math.min(1,(viewport.X-24)/214)
  toolbar.AnchorPoint=Vector2.new(1,1)
  toolbar.Position=UDim2.new(1,-18,1,-18)
  indicator.Position=UDim2.fromOffset(viewport.X/2,viewport.Y*0.32)'''+s[b:]
p.write_text(s)
p=Path('src/client/MainMenu.luau');s=p.read_text()
s=s.replace('local dark=Color3.fromRGB(27,27,64)','local dark=Color3.fromRGB(16,19,46)')
s=s.replace('panel.Position=UDim2.new(0,24,0.5,0)','panel.Position=UDim2.new(0,24,0.5,36)')
s=s.replace('corner.CornerRadius=UDim.new(0,20)','corner.CornerRadius=UDim.new(0,12)')
s=s.replace('stroke.Color=Color3.fromRGB(85,88,139); stroke.Thickness=1; stroke.Transparency=0.5','stroke.Color=gold; stroke.Thickness=1; stroke.Transparency=0.6')
s=s.replace('t.Font=Enum.Font.GothamBold; t.TextSize=size','t.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Bold); t.TextSize=size')
s=s.replace('label("P A D D L E U P",22,24,12,gold)','label("P A D D L E U P  /  SKYLINE CLUB",22,24,11,gold)')
s=s.replace('heading.Font=Enum.Font.GothamBold','heading.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy)')
s=s.replace('hide.Position=UDim2.new(1,-94,0,22)','hide.Position=UDim2.new(1,-94,0,58)')
s=s.replace('or 24,0.5,0)','or 24,0.5,36)')
s=s.replace('(camera.ViewportSize.Y-40)/panel.Size.Y.Offset','(camera.ViewportSize.Y-112)/panel.Size.Y.Offset')
p.write_text(s)
p=Path('src/client/MainMenuFlow.luau');s=p.read_text().replace('local Flow={}\n','local Flow={}\nlocal Assets=require(script.Parent:WaitForChild("FigmaAssets"))\n')
a=s.index('  local art=Art.mount(card,kind,accent)');b=s.index('\n  return art',a)
s=s[:a]+'''  local art
  if kind=="Classic" or kind=="Arcade" or kind=="Chaos" then
   card.BackgroundTransparency=1; card.Accent.Enabled=false
   local skin=Assets.image(card,kind=="Classic" and "vsAwayNameFrame" or kind=="Chaos" and "vsHomeNameFrame" or "vsRoundFrame",-8,-8,388,104)
   skin.Name="NeonFrame"; skin.ScaleType=Enum.ScaleType.Stretch; skin.ImageTransparency=0.12; skin.ZIndex=1
   art=Instance.new("Frame",card); art.Name="Artwork"; art.BackgroundTransparency=1
   local key=kind=="Classic" and "paddle" or kind=="Arcade" and "cleats" or "heatseeker"
   local icon=Assets.image(art,key,12,-4,114,96); icon.ScaleType=Enum.ScaleType.Fit; icon.ZIndex=2
  else art=Art.mount(card,kind,accent) end
  art.ZIndex=2'''+s[b:]
s=s.replace('card.Title.Font=Enum.Font.GothamBold;','card.Title.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Heavy);')
s=s.replace('card.Detail.Font=Enum.Font.GothamBold;','card.Detail.FontFace=Font.new(Font.fromEnum(Enum.Font.Nunito).Family,Enum.FontWeight.Bold);')
# Keep title and art separate, with a quiet mode label above the name.
s=s.replace('card.Title.TextSize=26; card.Title.Position=UDim2.fromOffset(18,13); card.Title.Size=UDim2.fromOffset(190,34)','card.Title.TextSize=28; card.Title.Position=UDim2.fromOffset(20,12); card.Title.Size=UDim2.fromOffset(198,34)')
s=s.replace('UDim2.fromOffset(18,50)','UDim2.fromOffset(20,50)')
p.write_text(s)
