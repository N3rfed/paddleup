local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog=require(Shared:WaitForChild("CosmeticCatalog"))
local Assets=require(Shared:WaitForChild("CosmeticAssets"))
local Shop={}
function Shop.start(player,network)
 local pg=player:WaitForChild("PlayerGui"); if pg:FindFirstChild("PaddleUpShop") then return end
 local UIS=game:GetService("UserInputService")
 local CAS=game:GetService("ContextActionService")
 local GuiService=game:GetService("GuiService")
 local Run=game:GetService("RunService")
 local remote=network:WaitForChild("Shop")
 local dark=Color3.fromRGB(26,39,44); local tile=Color3.fromRGB(38,55,60)
 local ivory=Color3.fromRGB(246,238,216); local muted=Color3.fromRGB(177,193,188)
 local mint=Color3.fromRGB(102,222,190); local gold=Color3.fromRGB(224,187,119); local coral=Color3.fromRGB(246,151,128)
 local gui=Instance.new("ScreenGui"); gui.Name="PaddleUpShop"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.DisplayOrder=75; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=pg
 local function box(parent,name,color)
  local f=Instance.new("Frame"); f.Name=name; f.BackgroundColor3=color or dark; f.BorderSizePixel=0; f.Parent=parent
  local round=Instance.new("UICorner"); round.CornerRadius=UDim.new(0,14); round.Parent=f; return f
 end
 local function label(parent,name,text,size,color)
  local l=Instance.new("TextLabel"); l.Name=name; l.Text=text; l.TextSize=size or 14; l.Font=Enum.Font.GothamBold
  l.TextColor3=color or ivory; l.BackgroundTransparency=1; l.TextXAlignment=Enum.TextXAlignment.Left; l.TextWrapped=true; l.Parent=parent; return l
 end
 local function button(parent,name,text,color)
  local b=Instance.new("TextButton"); b.Name=name; b.Text=text; b.Font=Enum.Font.GothamBold; b.TextSize=13
  b.BackgroundColor3=color or mint; b.TextColor3=dark; b.BorderSizePixel=0; b.Selectable=true; b.Parent=parent
  local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,10); corner.Parent=b; return b
 end
 local function rect(item,x,y,w,h) item.Position=UDim2.fromOffset(x,y); item.Size=UDim2.fromOffset(w,h) end
 local overlay=Instance.new("TextButton"); overlay.Name="ShopOverlay"; overlay.Text=""; overlay.AutoButtonColor=false; overlay.Modal=true
 overlay.Size=UDim2.fromScale(1,1); overlay.BackgroundColor3=Color3.new(); overlay.BackgroundTransparency=0.3; overlay.Visible=false; overlay.Parent=gui
 local panel=box(overlay,"GoodsBoutique",dark); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
 local panelScale=Instance.new("UIScale"); panelScale.Parent=panel
 local outline=Instance.new("UIStroke"); outline.Color=gold; outline.Transparency=0.4; outline.Parent=panel
 local brand=label(panel,"Brand","P A D D L E U P   /   GOODS",12,gold)
 local title=label(panel,"Title","Make it your game.",26,ivory)
 local balance=label(panel,"Currency","SPENDABLE XP  /  LOADING",18,mint)
 local progression=label(panel,"LifetimeXP","Loading club profile...",11,muted)
 local close=button(panel,"CloseShop","CLOSE",tile); close.TextColor3=ivory
 local categories=box(panel,"Categories",dark)
 local tabs={}
 local reset=button(panel,"RestoreDefault","USE ORIGINAL",tile); reset.TextColor3=ivory
 local list=Instance.new("ScrollingFrame"); list.Name="ItemGallery"; list.BackgroundTransparency=1; list.BorderSizePixel=0
 list.ScrollBarThickness=4; list.ScrollBarImageColor3=mint; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.CanvasSize=UDim2.new(); list.Parent=panel
 local grid=Instance.new("UIGridLayout"); grid.CellPadding=UDim2.fromOffset(10,10); grid.SortOrder=Enum.SortOrder.LayoutOrder; grid.Parent=list
 local detail=box(panel,"FittingRoom",tile)
 local previewTag=label(detail,"PreviewLabel","FITTING ROOM / ROTATING 3D PREVIEW",10,gold)
 local detailName=label(detail,"ItemName","",23,ivory)
 local description=label(detail,"Description","",12,muted)
 local price=label(detail,"Price","",17,gold)
 local action=button(detail,"ItemAction","SELECT AN ITEM")
 local retry=button(panel,"RetryShop","RETRY SAVE",tile); retry.TextColor3=mint
 local feedback=label(panel,"ShopFeedback","Try a design. Every finish is cosmetic; your game stays the same.",12,muted)
 local courtNote=label(detail,"CourtPolicy","",10,muted)
 local confirm=box(overlay,"PurchaseConfirmation",dark); confirm.ZIndex=10; confirm.Visible=false
 local confirmScale=Instance.new("UIScale"); confirmScale.Parent=confirm
 confirm.AnchorPoint=Vector2.new(0.5,0.5); confirm.Position=UDim2.fromScale(0.5,0.5)
 local confirmTitle=label(confirm,"ConfirmTitle","Confirm purchase",22,ivory); confirmTitle.ZIndex=11
 local confirmText=label(confirm,"ConfirmCost","",14,gold); confirmText.ZIndex=11
 local accept=button(confirm,"ConfirmBuy","BUY",mint); accept.ZIndex=11
 local cancel=button(confirm,"CancelBuy","CANCEL",tile); cancel.TextColor3=ivory; cancel.ZIndex=11
 local view,viewCamera,viewTarget,viewRadius,viewCategory
 local category="Paddles"; local selected; local cards={}; local state={inventory={},equipped={}}
 local token,lastRevision,serial,pending,lastResult=nil,0,0,nil,nil
 local closedTokens={}
 local angle=0; local openedAt=0; local pendingAt=0; local confirmId; local lastWidth
 local resize,refresh,choose,makeCards,setOpen
 local messages={Purchased="Purchased! This design is yours permanently.",Owned="You already own this design. No currency was spent.",
  Insufficient="Not enough spendable XP. Earn more through matches and club rewards.",Equipped="Equipped. Your selection has been saved.",
  Unequipped="Original appearance restored.",NotOwned="Purchase this design before equipping it.",InvalidItem="That item is unavailable.",Expired="This request expired. Check your balance and try again."}
 local function send(actionName,value)
  serial+=1
  if actionName~="Sync" and actionName~="Close" then pending=serial; pendingAt=os.clock() end
  remote:FireServer(actionName,serial,token,value)
 end
 local function viewport(parent,item,large)
  local v=Instance.new("ViewportFrame"); v.Name="ActualDesignPreview"; v.BackgroundTransparency=1
  v.Ambient=Color3.fromRGB(190,201,211); v.LightColor=Color3.fromRGB(255,244,220); v.LightDirection=Vector3.new(-1,-1,-2); v.Parent=parent
  local world=Instance.new("WorldModel"); world.Parent=v
  local asset=Assets.preview(item.id); asset.Parent=world
  local cf,size=asset:GetBoundingBox(); local target=cf.Position; local radius=math.max(size.X,size.Y,size.Z)
  local camera=Instance.new("Camera"); camera.FieldOfView=38; camera.Parent=v; v.CurrentCamera=camera
  local offset=item.category=="Courts" and Vector3.new(0.65,1.15,-1) or Vector3.new(0.28,0.12,-1.55)
  camera.CFrame=CFrame.lookAt(target+offset*radius,target)
  if large then viewCamera=camera; viewTarget=target; viewRadius=radius; viewCategory=item.category; angle=0 end
  return v
 end
 local function busy() return pending~=nil or state.pending or not state.ready end
 local function feedbackText(text,color) feedback.Text=text; feedback.TextColor3=color or muted end
 refresh=function()
  balance.Text=state.balance and string.format("%s  /  %d", "SPENDABLE XP",state.balance) or "SPENDABLE XP / UNAVAILABLE"
  progression.Text=state.level and string.format("LEVEL %d  /  %d : %d LEVEL XP  /  %d TOTAL EARNED XP",state.level,state.xp,state.required,state.totalXP) or "Your level and lifetime XP are kept separately from your shop balance."
  for id,card in pairs(cards) do
   local item=Catalog.ById[id]
   local owned=state.inventory[id]; local equipped=state.equipped[item.category]==id
   card.status.Text=equipped and "EQUIPPED" or owned and "OWNED" or (state.balance and state.balance<item.price and "LOCKED  /  " or "")..item.price.." XP"
   card.status.TextColor3=equipped and mint or owned and gold or muted
   card.stroke.Color=id==selected and mint or tile
  end
  for key,b in pairs(tabs) do b.BackgroundColor3=category==key and mint or tile; b.TextColor3=category==key and dark or ivory end
  reset.Active=not busy() and state.equipped[category]~=nil; reset.AutoButtonColor=reset.Active
  local item=Catalog.ById[selected]
  if item then
   local owned=state.inventory[selected]; local equipped=state.equipped[category]==selected
   price.Text=owned and (equipped and "EQUIPPED / SAVED" or "OWNED / READY TO WEAR") or string.format("%d SPENDABLE XP",item.price)
   action.Text=busy() and "SAVING / PLEASE WAIT" or equipped and "UNEQUIP" or owned and "EQUIP DESIGN" or state.balance and state.balance<item.price and "INSUFFICIENT XP" or "BUY DESIGN"
   action.Active=not busy() and (owned or state.balance and state.balance>=item.price) or false
   action.AutoButtonColor=action.Active; action.BackgroundColor3=action.Active and mint or Color3.fromRGB(83,99,98)
  end
  if state.error then feedbackText(state.error,coral) end
  if confirm.Visible and confirmId then
   local itemToBuy=Catalog.ById[confirmId]
   confirmText.Text=string.format("%s\nCost: %d spendable XP\nYour balance: %d\nLevel and total earned XP stay unchanged.",itemToBuy.name,itemToBuy.price,state.balance or 0)
   accept.Active=not busy() and state.balance~=nil and state.balance>=itemToBuy.price and not state.inventory[confirmId]
   accept.AutoButtonColor=accept.Active
  end
 end
 choose=function(id)
  selected=id; local item=Catalog.ById[id]
  if view then view:Destroy() end
  view=viewport(detail,item,true); detailName.Text=item.name; description.Text=item.description
  courtNote.Text=item.category=="Courts" and "Visible only to you. Court lines, lights and gameplay stay intact." or item.category=="Wearables" and "One wearable slot. Original avatar clothing and accessories are preserved underneath." or "Original grip, dimensions, hitbox and physics. Design is printed on both faces."
  refresh(); resize()
 end
 makeCards=function()
  for _,card in pairs(cards) do card.button:Destroy() end; cards={}
  for _,item in ipairs(Catalog.Items) do if item.category==category then
   local b=button(list,item.id,"",tile); b.LayoutOrder=#list:GetChildren(); b.ClipsDescendants=true
   local edge=Instance.new("UIStroke"); edge.Color=tile; edge.Thickness=2; edge.Parent=b
   local v=viewport(b,item,false); v.Position=UDim2.new(0,4,0,3); v.Size=UDim2.new(1,-8,1,-53)
   local name=label(b,"Name",item.name,13,ivory); name.Position=UDim2.new(0,10,1,-48); name.Size=UDim2.new(1,-20,0,23)
   local status=label(b,"Ownership","",10,muted); status.Position=UDim2.new(0,10,1,-25); status.Size=UDim2.new(1,-20,0,20)
   cards[item.id]={button=b,status=status,stroke=edge}
   b.Activated:Connect(function() if not confirm.Visible then choose(item.id) end end)
  end end
  list.CanvasPosition=Vector2.zero
 end
 for index,key in ipairs(Catalog.Categories) do
  local b=button(categories,key,Catalog.Labels[key],tile); tabs[key]=b
  b.Activated:Connect(function()
   if confirm.Visible then return end
   category=key; makeCards()
   for _,item in ipairs(Catalog.Items) do if item.category==category then choose(item.id); break end end
  end)
 end
 resize=function()
  local camera=workspace.CurrentCamera; local size=camera and camera.ViewportSize or Vector2.new(1280,800)
  local uiScale=math.min(1,(size.Y-24)/680)
  panelScale.Scale=uiScale; confirmScale.Scale=uiScale
  local w=math.min(1100,(size.X-24)/uiScale); local h=math.max(680,math.min(760,size.Y-24)); local small=w<700
  panel.Size=UDim2.fromOffset(w,h)
  rect(brand,20,14,w-124,18); rect(title,20,38,w-40,34); rect(close,w-92,14,72,30)
  rect(balance,20,80,w-40,26); rect(progression,20,109,w-40,30)
  rect(categories,20,146,w-40,42)
  local tabW=(w-48)/3
  for i,key in ipairs(Catalog.Categories) do rect(tabs[key],(i-1)*(tabW+4),0,tabW,40); tabs[key].TextSize=small and 10 or 13 end
  rect(feedback,20,h-64,w-140,48); rect(retry,w-115,h-55,95,32)
  local bodyY=201; local bodyH=h-bodyY-78
  if small then
   local galleryH=math.max(96,math.floor(bodyH*0.39))
   rect(reset,20,bodyY,w-40,28); rect(list,20,bodyY+35,w-40,galleryH)
   local detailY=bodyY+42+galleryH
   rect(detail,20,detailY,w-40,math.max(130,h-detailY-78))
   local dw=w-40; local dh=detail.Size.Y.Offset; local artW=math.floor(dw*0.39)
   if view then rect(view,5,30,artW,math.max(80,dh-60)) end
   rect(previewTag,12,7,dw-24,18); previewTag.TextSize=8
   rect(detailName,artW+10,29,dw-artW-20,28); detailName.TextSize=17
   rect(description,artW+10,58,dw-artW-20,math.max(35,dh-133)); description.TextSize=10
   rect(price,artW+10,dh-74,dw-artW-20,25); price.TextSize=12
   rect(action,artW+10,dh-44,dw-artW-20,34); action.TextSize=11
   courtNote.Visible=false
   local cw=(w-62)/2; grid.CellSize=UDim2.fromOffset(cw,138)
  else
   local dw=math.floor(w*0.35); local lw=w-dw-58
   rect(reset,20,bodyY,lw,28); rect(list,20,bodyY+38,lw,bodyH-38)
   rect(detail,w-dw-20,bodyY,dw,bodyH)
   rect(previewTag,16,12,dw-32,18)
   local vh=math.max(125,bodyH-235)
   if view then rect(view,10,35,dw-20,vh) end
   rect(detailName,18,vh+38,dw-36,34); detailName.TextSize=23
   rect(description,18,vh+78,dw-36,54); description.TextSize=12
   rect(price,18,bodyH-101,dw-36,26); price.TextSize=16
   rect(action,18,bodyH-70,dw-36,38)
   rect(courtNote,18,bodyH-28,dw-36,25); courtNote.Visible=true
   grid.CellSize=UDim2.fromOffset((lw-30)/3,math.max(156,math.min(210,(bodyH-58)/2)))
  end
  local cw=math.min(400,w-24); confirm.Size=UDim2.fromOffset(cw,270)
  rect(confirmTitle,20,18,cw-40,34); rect(confirmText,20,62,cw-40,126)
  rect(accept,20,208,(cw-50)/2,42); rect(cancel,30+(cw-50)/2,208,(cw-50)/2,42)
 end
 setOpen=function(value)
  if not value and token then closedTokens[token]=true end
  overlay.Visible=value; confirm.Visible=false; confirmId=nil; player:SetAttribute("ShopOpen",value)
  if value then
   openedAt=os.clock(); resize(); refresh()
   UIS.MouseBehavior=Enum.MouseBehavior.Default; UIS.MouseIconEnabled=true
   CAS:BindActionAtPriority("ShopControls",function() return Enum.ContextActionResult.Sink end,false,Enum.ContextActionPriority.High.Value+30,
    Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,Enum.KeyCode.Space,Enum.KeyCode.Thumbstick1)
   if UIS.GamepadEnabled then GuiService.SelectedObject=tabs[category] end
  else
   CAS:UnbindAction("ShopControls"); GuiService.SelectedObject=nil; send("Close")
  end
 end
 close.Activated:Connect(function() setOpen(false) end)
 cancel.Activated:Connect(function() confirm.Visible=false; confirmId=nil; if UIS.GamepadEnabled then GuiService.SelectedObject=action end end)
 accept.Activated:Connect(function()
  if not accept.Active or not confirmId then return end
  local id=confirmId; confirm.Visible=false; confirmId=nil; send("Buy",id); feedbackText("Saving purchase...",gold); refresh()
 end)
 action.Activated:Connect(function()
  if not action.Active or not selected then return end
  if state.inventory[selected] then
   if state.equipped[category]==selected then send("Unequip",category) else send("Equip",selected) end
  else
   confirmId=selected; confirm.Visible=true; refresh()
   if UIS.GamepadEnabled then GuiService.SelectedObject=cancel end
  end
  refresh()
 end)
 reset.Activated:Connect(function() if reset.Active then send("Unequip",category); refresh() end end)
 retry.Activated:Connect(function() if overlay.Visible then send("Retry"); refresh() end end)
 UIS.InputBegan:Connect(function(input,processed)
  if overlay.Visible and (input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB) then
   if confirm.Visible then confirm.Visible=false; confirmId=nil else setOpen(false) end
  end
 end)
 local function leaveShop() if overlay.Visible then setOpen(false) end end
 player:GetAttributeChangedSignal("SessionMode"):Connect(function() if player:GetAttribute("SessionMode")~="Lobby" then leaveShop() end end)
 player:GetAttributeChangedSignal("CheckInOpen"):Connect(function() if player:GetAttribute("CheckInOpen") then leaveShop() end end)
 player.CharacterRemoving:Connect(leaveShop)
 remote.OnClientEvent:Connect(function(packet)
  if type(packet)~="table" or type(packet.revision)~="number" or packet.revision<=lastRevision then return end
  lastRevision=packet.revision; serial=math.max(serial,packet.ack or 0)
  if packet.open and closedTokens[packet.token] then return end
  if packet.open then token=packet.token end
  state=packet; state.inventory=packet.inventory or {}; state.equipped=packet.equipped or {}
  if pending and (packet.ack or 0)>=pending and not packet.pending then pending=nil end
  if packet.result and packet.result.id~=lastResult and not packet.pending then
   lastResult=packet.result.id; feedbackText(messages[packet.result.kind] or "Selection saved.",packet.result.kind=="Insufficient" and coral or mint)
  end
  if packet.message then pending=nil; feedbackText(packet.message,coral) end
  if state.pending then feedbackText("Saving your selection. Purchases appear only after confirmation.",gold) end
  if packet.open then setOpen(true) end
  refresh()
 end)
 local lastSize
 local connection=Run.RenderStepped:Connect(function(dt)
  if not overlay.Visible then return end
  local size=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
  if size~=lastSize then lastSize=size; resize() end
  if viewCamera then
   angle+=dt*0.25
   local turn=math.sin(angle)*0.32
   local offset=viewCategory=="Courts" and Vector3.new(math.sin(angle)*0.6,1.25,-1.1) or Vector3.new(math.sin(turn)*1.55,0.16,-math.cos(turn)*1.55)
   viewCamera.CFrame=CFrame.lookAt(viewTarget+offset*viewRadius,viewTarget)
  end
  if pending and os.clock()-pendingAt>10 then feedbackText("Waiting for save confirmation. Retry resumes the pending save safely.",gold) end
  if os.clock()-openedAt>180 then feedbackText("Your browsing session expired. Close and press E at the counter to reopen.",gold) end
 end)
 gui.Destroying:Connect(function() connection:Disconnect(); CAS:UnbindAction("ShopControls"); player:SetAttribute("ShopOpen",false) end)
 makeCards(); choose("paddle_porcelain"); send("Sync")
 return gui
end
return Shop
