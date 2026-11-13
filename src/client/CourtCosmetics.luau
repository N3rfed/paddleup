-- Client-only surface finishes. Never replicate one player's choice onto an opponent's court.
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
while Shared:GetAttribute("CosmeticsVersion")~=2 do
 Shared:GetAttributeChangedSignal("CosmeticsVersion"):Wait()
end
local Assets=require(Shared:WaitForChild("CosmeticAssets"))
local Court={}
function Court.start(player)
 local current,id,queued
 local function update()
  queued=false
  local side=player:GetAttribute("CourtSide") or 0
  local slot=player:GetAttribute("CourtId")
  local nextRoot=side~=0 and slot and workspace:FindFirstChild(slot==0 and "PaddleUp" or "PaddleUpCourt"..slot) or nil
  local nextId=player:GetAttribute("EquippedCourt") or ""
  if current~=nextRoot or id~=nextId then
   if current and current.Parent then Assets.court(current,nil) end
   current=nextRoot; id=nextId
  end
  if current and current.Parent then Assets.court(current,id) end
 end
 local function schedule()
  if queued then return end; queued=true; task.defer(update)
 end
 for _,name in ipairs({"CourtId","CourtSide","EquippedCourt","CourtEnvironment"}) do player:GetAttributeChangedSignal(name):Connect(schedule) end
 workspace.DescendantAdded:Connect(function(p)
  if p.Name=="Playing surface" or p.Name=="Kitchen" or p.Name=="Court surround" or p.Name:match("^PaddleUpCourt%d+$") then schedule() end
 end)
 schedule()
end
return Court
