local TweenService=game:GetService("TweenService")
local Text={}
local active={}
local colors={good=Color3.fromRGB(105,255,159),neutral=Color3.fromRGB(188,198,207),bad=Color3.fromRGB(255,95,109)}

function Text.show(character,message,tone)
 local root=character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Body") or character:FindFirstChild("Head"))
 if not root then return end
 -- Only the newest result remains over each player during rapid exchanges.
 local previous=active[character]
 if previous then previous.anchor:Destroy() end
 local anchor=Instance.new("Part")
 anchor.Name="Floating shot text"; anchor.Anchored=true; anchor.Transparency=1
 anchor.Size=Vector3.one*0.1; anchor.CanCollide=false; anchor.CanTouch=false; anchor.CanQuery=false; anchor.CastShadow=false
 anchor.Position=root.Position+Vector3.new(0,4.7,0); anchor.Parent=workspace
 local gui=Instance.new("BillboardGui")
 gui.Name="ShotFeedback"; gui.Adornee=anchor; gui.Size=UDim2.fromOffset(290,54)
 gui.AlwaysOnTop=true
 gui.MaxDistance=180; gui.LightInfluence=0; gui.Parent=anchor
 local label=Instance.new("TextLabel")
 label.AnchorPoint=Vector2.new(0.5,0.5); label.Position=UDim2.fromScale(0.5,0.5)
 label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
 label.Text=message; label.Font=Enum.Font.GothamBold; label.TextSize=17
 label.TextWrapped=true; label.TextColor3=colors[tone] or colors.neutral
 label.TextStrokeColor3=Color3.fromRGB(12,25,29); label.TextStrokeTransparency=0.2; label.Parent=gui
 TweenService:Create(label,TweenInfo.new(0.4,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,0.85),{TextTransparency=1,TextStrokeTransparency=1}):Play()
 active[character]={anchor=anchor,root=root,position=root.Position,age=0}
 return gui
end

-- Updated after the camera: follow the stable root, never animated head bob.
function Text.update(dt)
 for character,entry in pairs(active) do
  entry.age+=dt
  if not character.Parent or not entry.root.Parent or entry.age>=1.3 then
   entry.anchor:Destroy(); active[character]=nil
  else
   entry.position=entry.position:Lerp(entry.root.Position,1-math.exp(-dt*16))
   entry.anchor.Position=entry.position+Vector3.new(0,4.7+entry.age*0.8,0)
  end
 end
end

function Text.destroy()
 for character,entry in pairs(active) do entry.anchor:Destroy(); active[character]=nil end
end

return Text
