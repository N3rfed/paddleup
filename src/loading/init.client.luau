-- ReplicatedFirst covers the initial arrival before ordinary player scripts run.
local Players=game:GetService("Players")
local ReplicatedFirst=game:GetService("ReplicatedFirst")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui")
gui.Name="ArrivalLoading"; gui.IgnoreGuiInset=true; gui.ResetOnSpawn=false; gui.DisplayOrder=1000
local cover=Instance.new("Frame",gui)
cover.Size=UDim2.fromScale(1,1); cover.BackgroundColor3=Color3.fromRGB(12,24,29); cover.BorderSizePixel=0
cover.Active=true
local title=Instance.new("TextLabel",cover)
title.Size=UDim2.fromScale(0.7,0.08); title.Position=UDim2.fromScale(0.15,0.43)
title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBold; title.TextSize=28
title.TextColor3=Color3.fromRGB(240,232,213); title.Text="P A D D L E U P"
local status=title:Clone(); status.Parent=cover; status.Position=UDim2.fromScale(0.15,0.53)
status.TextSize=16; status.Text="Preparing the penthouse..."
gui.Parent=player:WaitForChild("PlayerGui")
ReplicatedFirst:RemoveDefaultLoadingScreen()
if not game:IsLoaded() then game.Loaded:Wait() end
local function ready(root)
 local expected=root and root:GetAttribute("ExpectedDescendants")
 return expected and #root:GetDescendants()>=expected
end
local lobby
repeat
 lobby=workspace:FindFirstChild("PaddleUpLobby")
 local city=workspace:FindFirstChild("LobbyCity")
 local cityExpected=lobby and lobby:GetAttribute("CityExpected")
 if ready(lobby) and (not cityExpected or ready(city)) then break end
 task.wait(0.05)
until false
pcall(function() game:GetService("ContentProvider"):PreloadAsync({lobby}) end)
-- Keep the cover through character placement and the first fully rendered frames.
local character=player.Character or player.CharacterAdded:Wait()
character:WaitForChild("HumanoidRootPart")
local floor=lobby:FindFirstChild("Cream marble floor",true)
while player.Character==character and (player:GetAttribute("SessionMode")==nil or player:GetAttribute("SessionMode")=="Lobby")
 and (character.HumanoidRootPart.Position-floor.Position).Magnitude>150 do task.wait(0.05) end
RunService.RenderStepped:Wait(); RunService.RenderStepped:Wait()
local tween=game:GetService("TweenService"):Create(cover,TweenInfo.new(0.25),{BackgroundTransparency=1})
title.Visible=false; status.Visible=false; tween:Play(); tween.Completed:Wait()
gui:Destroy()
