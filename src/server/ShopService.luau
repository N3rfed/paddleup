local Catalog=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CosmeticCatalog"))
local Assets=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CosmeticAssets"))
local Shop={}
function Shop.start(network,lobby,progression)
 local Players=game:GetService("Players")
 local Http=game:GetService("HttpService")
 local remote=Instance.new("RemoteEvent"); remote.Name="Shop"; remote.Parent=network
 local counter=assert(lobby:FindFirstChild("Boutique stone top",true),"Existing boutique counter is missing")
 local point=Instance.new("Attachment"); point.Name="ShopInteraction"; point.Position=Vector3.new(0,1.4,2.8); point.Parent=counter
 local prompt=Instance.new("ProximityPrompt"); prompt.Name="OpenShop"; prompt.ActionText="Browse Goods"; prompt.ObjectText="PaddleUp Goods"
 prompt.KeyboardKeyCode=Enum.KeyCode.E; prompt.GamepadKeyCode=Enum.KeyCode.ButtonX
 prompt.MaxActivationDistance=12; prompt.RequiresLineOfSight=false; prompt.HoldDuration=0; prompt.Parent=point
 -- Real catalog samples on the counter; built with exactly the equipped paddle builder.
 local display=Instance.new("Model"); display.Name="ShopCatalogDisplay"; display.Parent=lobby
 for i,id in ipairs({"paddle_porcelain","paddle_tour","paddle_afterglow","paddle_confetti","paddle_prism","paddle_lotus"}) do
  local sample=Assets.preview(id); sample:ScaleTo(0.46)
  sample:PivotTo(counter.CFrame*CFrame.new((i-3.5)*1.2,1.15,0)*CFrame.Angles(0,math.pi,0)); sample.Parent=display
 end
 local sign=Instance.new("Part"); sign.Name="Goods welcome plaque"; sign.Size=Vector3.new(7.6,0.75,0.05)
 sign.CFrame=counter.CFrame*CFrame.new(0,-0.65,2.24); sign.Anchored=true; sign.CanCollide=false; sign.CanTouch=false; sign.CanQuery=false
 sign.Color=Color3.fromRGB(32,63,55); sign.Parent=display
 local gui=Instance.new("SurfaceGui"); gui.Face=Enum.NormalId.Back; gui.PixelsPerStud=60; gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.Parent=sign
 local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1
 label.Text="GOODS / E TO BROWSE"; label.TextColor3=Color3.fromRGB(237,218,168); label.Font=Enum.Font.GothamBold; label.TextScaled=true; label.Parent=gui
 local sessions={}
 local function near(player)
  local c=player.Character; local root=c and c:FindFirstChild("HumanoidRootPart"); local h=c and c:FindFirstChildOfClass("Humanoid")
  return player.Parent==Players and player:GetAttribute("SessionMode")=="Lobby" and root and h and h.Health>0 and (root.Position-point.WorldPosition).Magnitude<=12
 end
 local function send(player,open,message)
  local session=sessions[player]; if not session then return end
  local entry=progression.entries[player]
  local data=entry and entry.data
  session.revision+=1
  remote:FireClient(player,{open=open==true,token=session.token,revision=session.revision,ack=session.ack,
   ready=data~=nil and not entry.failed,pending=entry and (entry.running or #entry.queue>0) or false,
   error=entry and entry.failed and entry.failure and entry.failure.message or nil,
   level=data and data.level,totalXP=data and data.totalXP,xp=data and data.xp,
   required=data and require(script.Parent:WaitForChild("ProgressionRules")).required(data.level),
   balance=data and data.spendableXP,inventory=data and table.clone(data.inventory) or {},
   equipped=data and table.clone(data.equipped) or {},result=entry and entry.shopResult,message=message})
 end
 local function sessionFor(player)
  if not sessions[player] then sessions[player]={revision=0,ack=0,last=-math.huge,lastPrompt=-math.huge} end
  return sessions[player]
 end
 prompt.Triggered:Connect(function(player)
  if progression.closing or not near(player) then return end
  local s=sessionFor(player); local now=os.clock()
  if now-s.lastPrompt<1 then return end
  s.lastPrompt=now; s.token=Http:GenerateGUID(false); s.expires=now+180
  send(player,true); progression:refreshShop(player)
 end)
 remote.OnServerEvent:Connect(function(player,action,requestId,token,value)
  if progression.closing or type(action)~="string" then return end
  local s=sessionFor(player); local now=os.clock()
  if type(requestId)~="number" or requestId%1~=0 or requestId<=s.ack or requestId>1e9 then return end
  if action=="Close" then if token==s.token then s.expires=nil end; return end
  if action~="Sync" and action~="Retry" and action~="Buy" and action~="Equip" and action~="Unequip" then return end
  if now-s.last<0.4 then
   s.ack=requestId
   if not s.lastRateFeedback or now-s.lastRateFeedback>=0.4 then
    s.lastRateFeedback=now; send(player,false,"Please wait a moment before another shop action.")
   end
   return
  end
  s.last=now; s.ack=requestId
  if action=="Sync" then send(player); return end
  if token~=s.token or not s.expires or now>s.expires or not near(player) then
   send(player,false,"Return to PaddleUp Goods and press E to continue."); return
  end
  if action=="Retry" then progression:refreshShop(player,true); send(player); return end
  if type(value)~="string" or #value>80 then send(player,false,"Choose a valid item."); return end
  if action=="Unequip" then
   if not Catalog.Labels[value] then return end
  elseif not Catalog.ById[value] then send(player,false,"That item is unavailable."); return end
  local ok
  if action=="Unequip" then ok=progression:shop(player,"ShopUnequip",nil,value)
  else ok=progression:shop(player,"Shop"..action,value,nil) end
  if not ok then send(player,false,"A save is pending or your profile is unavailable. Wait or Retry.") else send(player) end
 end)
 progression:subscribe(function(entry) if sessions[entry.player] then send(entry.player) end end)
 Players.PlayerRemoving:Connect(function(player) sessions[player]=nil end)
 return {prompt=prompt,point=point,remote=remote,near=near}
end
return Shop
