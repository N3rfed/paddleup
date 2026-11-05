local Loadout={}
function Loadout.start(player,network)
 local remote=network:WaitForChild("ArcadeLoadout")
 local UI=require(script.Parent:WaitForChild("ArcadeDeckUI"))
 local gui,waiting
 local function clear()
  if gui then gui:Destroy(); gui=nil end
  if waiting then waiting:Destroy(); waiting=nil end
 end
 remote.OnClientEvent:Connect(function(data)
  if data.kind=="chosen" then return end
  clear()
  if data.kind=="open" then
   gui=UI.open(player,function(deck)
    gui=nil
    waiting=Instance.new("ScreenGui"); waiting.Name="WaitingForLoadouts"; waiting.ResetOnSpawn=false
    local label=Instance.new("TextLabel",waiting)
    label.AnchorPoint=Vector2.new(0.5,0); label.Position=UDim2.fromScale(0.5,0.12)
    label.Size=UDim2.fromOffset(320,48); label.BackgroundColor3=Color3.fromRGB(13,19,31)
    label.BorderSizePixel=0; label.Text="Waiting for other players..."
    label.Font=Enum.Font.GothamMedium; label.TextSize=16; label.TextColor3=Color3.fromRGB(246,246,255)
    Instance.new("UICorner",label).CornerRadius=UDim.new(0,8)
    waiting.Parent=player:WaitForChild("PlayerGui")
    remote:FireServer(data.id,deck)
   end,function()
    gui=nil; network:WaitForChild("Session"):FireServer("Lobby")
   end,{endsAt=data.endsAt})
  end
 end)
 player:GetAttributeChangedSignal("SessionMode"):Connect(function()
  if player:GetAttribute("SessionMode")=="Lobby" or player:GetAttribute("SessionMode")=="Spectate" then clear() end
 end)
end
return Loadout
