-- Server-visible paddle art and wearable geometry; no gameplay state is changed.
local Assets=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CosmeticAssets"))
local Service={}
function Service.start(progression)
 local Players=game:GetService("Players")
 local records={}
 local function apply(player)
  local record=records[player]; local character=player.Character
  if not record or not character or not record.equipped then return end
  local face=character:FindFirstChild("PaddleFace")
  if face then Assets.paddle(face,record.equipped.Paddles) end
  Assets.wear(character,record.equipped.Wearables)
 end
 local function deferApply(player)
  local record=records[player]; if not record or record.queued then return end
  record.queued=true
  task.defer(function() if records[player]==record then record.queued=false; apply(player) end end)
 end
 local function character(player,c)
  local record=records[player]; if not record then return end
  if record.descendant then record.descendant:Disconnect() end
  record.descendant=c.ChildAdded:Connect(function(part)
   if part.Name=="PaddleFace" or part.Name=="UpperTorso" or part.Name=="Torso" or part.Name=="Head"
    or part.Name=="LeftHand" or part.Name=="RightHand" or part.Name=="Left Arm" or part.Name=="Right Arm" then deferApply(player) end
  end)
  deferApply(player)
 end
 local function add(player)
  if records[player] then return end
  local record={}; records[player]=record
  record.added=player.CharacterAdded:Connect(function(c) character(player,c) end)
  record.appearance=player.CharacterAppearanceLoaded:Connect(function() deferApply(player) end)
  if player.Character then character(player,player.Character) end
 end
 Players.PlayerAdded:Connect(add)
 Players.PlayerRemoving:Connect(function(player)
  local record=records[player]; if not record then return end
  for _,key in ipairs({"added","appearance","descendant"}) do if record[key] then record[key]:Disconnect() end end
  records[player]=nil
 end)
 for _,player in ipairs(Players:GetPlayers()) do add(player) end
 progression:subscribe(function(entry)
  local player=entry.player; local data=entry.data
  if not data or entry.failed or player.Parent~=Players then return end
  add(player); local record=records[player]
  local e=data.equipped
  local signature=(e.Paddles or "").."|"..(e.Wearables or "").."|"..(e.Courts or "")
  if record.signature==signature then return end
  record.signature=signature; record.equipped=table.clone(e)
  player:SetAttribute("EquippedPaddle",e.Paddles or "")
  player:SetAttribute("EquippedWearable",e.Wearables or "")
  player:SetAttribute("EquippedCourt",e.Courts or "")
  deferApply(player)
 end)
 return {apply=apply}
end
return Service
