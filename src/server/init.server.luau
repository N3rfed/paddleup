-- Server coordinator: matchmaking, court lifecycle and match-scoped input.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
game:GetService("StarterPlayer").EnableMouseLockOption=false
local template=require(script:WaitForChild("World")).build()
require(script:WaitForChild("LobbyWorld")).build()
require(script:WaitForChild("DayNightCycle")).start()
local shared=ReplicatedStorage:FindFirstChild("Shared") or Instance.new("Folder",ReplicatedStorage)
shared.Name="Shared"
if not shared:FindFirstChild("MatchRules") then script.MatchRules:Clone().Parent=shared end
local network=ReplicatedStorage:FindFirstChild("PaddleUp") or Instance.new("Folder",ReplicatedStorage)
network.Name="PaddleUp"
for _,name in ipairs({"Input","State","Feedback"}) do
 if not network:FindFirstChild(name) then local event=Instance.new("RemoteEvent",network); event.Name=name end
end
local Runtime=require(script:WaitForChild("MatchRuntime"))
local Courts=require(script:WaitForChild("MatchCourts"))
local runtimes={}
local lobby
local function viewers(matchId)
 local result={}
 for _,player in ipairs(Players:GetPlayers()) do
  local selected=lobby.model:match(player.UserId)
  if selected and selected.id==matchId then table.insert(result,player) end
 end
 return result
end
local function paddle(character)
 local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
 if not hand then return end
 local function attach(name,size,offset,color)
  local p=Instance.new("Part")
  p.Name=name; p.Size=size; p.Color=color; p.Material=Enum.Material.SmoothPlastic
  p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true
  p.CFrame=hand.CFrame*offset; p.Parent=character
  local weld=Instance.new("WeldConstraint",p); weld.Part0=hand; weld.Part1=p
  return p
 end
 attach("PaddleGrip",Vector3.new(0.3,1.2,0.3),CFrame.new(0,-0.7,0),Color3.fromRGB(35,47,52))
 local face=attach("PaddleFace",Vector3.new(1.65,2,0.3),CFrame.new(0,-2,0),Color3.fromRGB(31,193,180))
 face:SetAttribute("Paddle",true)
end

local function spawnLobby(player,character)
 local root=character:WaitForChild("HumanoidRootPart",10)
 local humanoid=character:WaitForChild("Humanoid",10)
 if not root or not humanoid then return end
 local match=lobby.model:match(player.UserId)
 if lobby.model:playing(player.UserId) and match and runtimes[match.id] then
  runtimes[match.id].spawn(player,character); return
 end
 player:SetAttribute("CourtSide",0)
 character:SetAttribute("ShotChargeAt",nil)
 humanoid.WalkSpeed=18; humanoid.UseJumpPower=true; humanoid.JumpPower=38
 character:PivotTo(CFrame.lookAt(Vector3.new(-850,257.7,32),Vector3.new(-850,257.7,0)))
 root.AssemblyLinearVelocity=Vector3.zero
 if not character:FindFirstChild("PaddleFace") then paddle(character) end
end
lobby=require(script:WaitForChild("LobbyService")).new(network,{
 focus=function(player,match)
  local runtime=match and runtimes[match.id]
  player.ReplicationFocus=runtime and runtime.focus or nil
 end,
 score=function(id) local runtime=runtimes[id]; return runtime and runtime.score() or {0,0} end,
 start=function(match)
  local court=Courts.create(template,match)
  runtimes[match.id]=Runtime.new(match,court,network,viewers,function(id,message) lobby:finish(id,message) end)
 end,
 stop=function(match)
  local runtime=runtimes[match.id]
  runtimes[match.id]=nil
  if runtime then runtime.destroy() end
  for _,id in ipairs(match.members) do
   local player=Players:GetPlayerByUserId(id)
   if player then
    player:SetAttribute("CourtSide",0)
    if player.Character then task.spawn(spawnLobby,player,player.Character) end
   end
  end
 end,
})
local connections={}
local swings={}
local function addPlayer(player)
 if connections[player] then return end
 player:SetAttribute("CourtSide",0)
 lobby:add(player)
 connections[player]=player.CharacterAdded:Connect(function(character) spawnLobby(player,character) end)
 if player.Character then task.spawn(spawnLobby,player,player.Character) end
end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(player)
 lobby:remove(player)
 if connections[player] then connections[player]:Disconnect(); connections[player]=nil end
 swings[player]=nil
end)
for _,player in ipairs(Players:GetPlayers()) do addPlayer(player) end
network.Input.OnServerEvent:Connect(function(player,action,value)
 local match=lobby.model:match(player.UserId)
 if lobby.model:playing(player.UserId) and match and runtimes[match.id] then
  runtimes[match.id].input(player,action,value)
 elseif action=="LobbySwing" and player:GetAttribute("LobbyStatus")=="Lobby" then
  local now=os.clock()
  local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
  if not humanoid or humanoid.Health<=0 or now<(swings[player] or 0) then return end
  swings[player]=now+0.28
  for _,recipient in ipairs(Players:GetPlayers()) do
   if recipient:GetAttribute("LobbyStatus")=="Lobby" then
    network.Feedback:FireClient(recipient,{userId=player.UserId,backhand=false,soft=value==true and "drop" or nil},"swing")
   end
  end
 end
end)
local broadcast=0
RunService.Heartbeat:Connect(function(dt)
 for _,runtime in pairs(runtimes) do runtime.step(dt) end
 for _,player in ipairs(Players:GetPlayers()) do
  if not lobby.model:playing(player.UserId) then
   local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
   local relative=root and root.Position-Vector3.new(-850,0,0)
   if root and (relative.X*relative.X+relative.Z*relative.Z>210^2 or root.Position.Y<240 or root.Position.Y>290) then
    player.Character:PivotTo(CFrame.new(-850,257.7,32)); root.AssemblyLinearVelocity=Vector3.zero
   end
  end
 end
 broadcast+=dt
 if broadcast>=1 then broadcast=0; lobby:broadcast() end
end)
