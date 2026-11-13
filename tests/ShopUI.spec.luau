return function(source,Catalog,Assets)
 local function signal()
  local items={}; local s={}
  function s:Connect(fn) local c={Connected=true}; function c:Disconnect() self.Connected=false end; table.insert(items,{fn=fn,c=c}); return c end
  function s:Fire(...) for _,i in ipairs(items) do if i.c.Connected then i.fn(...) end end end
  return s
 end
 local folder=Instance.new("Folder"); local changed={}; local attributes={SessionMode="Lobby"}
 local player={CharacterRemoving=signal()}
 function player:WaitForChild() return folder end
 function player:SetAttribute(k,v) attributes[k]=v; if changed[k] then changed[k]:Fire() end end
 function player:GetAttribute(k) return attributes[k] end
 function player:GetAttributeChangedSignal(k) changed[k]=changed[k] or signal(); return changed[k] end
 local requests={}; local remote={OnClientEvent=signal()}
 function remote:FireServer(action,id,token,value) table.insert(requests,{action=action,id=id,token=token,value=value}) end
 local input={InputBegan=signal(),GamepadEnabled=false}
 local render=signal(); local camera={ViewportSize=Vector2.new(1280,800)}
 local shared={GetAttribute=function() return 2 end,WaitForChild=function(_,name) return name end}
 local services={ReplicatedStorage={WaitForChild=function() return shared end},UserInputService=input,GuiService={},
  ContextActionService={BindActionAtPriority=function() end,UnbindAction=function() end},RunService={RenderStepped=render}}
 local captures={}
 local instrumented=source:gsub("(%w+)%.Activated:Connect%(function%(","captureButton(%1,function(")
 local fn=assert(loadstring(instrumented))
 setfenv(fn,setmetatable({workspace={CurrentCamera=camera},require=function(name) return ({CosmeticCatalog=Catalog,CosmeticAssets=Assets})[name] end,
  captureButton=function(b,callback) captures[b.Name]=callback; return b.Activated:Connect(callback) end,
  game={GetService=function(_,name) return assert(services[name],name) end}},{__index=getfenv()}))
 local UI=fn(); local revision=0; local current={ready=true,pending=false,level=4,xp=20,required=340,totalXP=900,balance=1000,inventory={},equipped={}}
 local function publish(open)
  revision+=1; local packet=table.clone(current); packet.revision=revision; packet.ack=requests[#requests].id; packet.open=open; packet.token="window-1"
  remote.OnClientEvent:Fire(packet)
 end
 local ok,err=pcall(function()
  local gui=UI.start(player,{WaitForChild=function() return remote end}); UI.start(player,{WaitForChild=function() return remote end})
  assert(#folder:GetChildren()==1)
  publish(true)
  local panel=gui.ShopOverlay.GoodsBoutique
  assert(attributes.ShopOpen and panel.Currency.Text:find("1000",1,true) and panel.LifetimeXP.Text:find("900",1,true))
  assert(#panel.ItemGallery:GetChildren()==7,"Six paddle cards and their layout are present")
  assert(panel.FittingRoom:FindFirstChild("ActualDesignPreview"):FindFirstChildOfClass("WorldModel"),"Detail preview contains real geometry")
  captures.ItemAction(); assert(gui.ShopOverlay.PurchaseConfirmation.Visible and requests[#requests].action=="Sync","Buying requires confirmation first")
  captures.ConfirmBuy(); assert(requests[#requests].action=="Buy" and requests[#requests].value=="paddle_porcelain")
  current.inventory={paddle_porcelain=true}; current.balance=820
  current.pending=true; current.result={id="purchase-1",kind="Purchased"}; publish(false)
  assert(panel.FittingRoom.ItemAction.Text=="SAVING / PLEASE WAIT")
  current.pending=false; publish(false)
  assert(panel.ShopFeedback.Text:find("Purchased!",1,true),"Final save confirmation replaces pending feedback")
  captures.ItemAction(); assert(requests[#requests].action=="Equip")
  current.equipped={Paddles="paddle_porcelain"}; publish(false)
  captures.ItemAction(); assert(requests[#requests].action=="Unequip" and requests[#requests].value=="Paddles")
  current.equipped={}; publish(false)
  for _,key in ipairs({"Wearables","Courts","Paddles"}) do
   captures[key]()
   local expected=key=="Paddles" and 7 or key=="Wearables" and 11 or 7
   assert(#panel.ItemGallery:GetChildren()==expected,"Each category has the intended visible designs")
  end
  captures.Wearables(); captures.FemaleFit()
  assert(panel.FemaleFit.Visible and panel.ItemGallery:FindFirstChild("wear_white_female") and not panel.ItemGallery:FindFirstChild("wear_club"),"Female browsing uses female outfit variants")
  assert(panel.FittingRoom.ActualDesignPreview.WorldModel:FindFirstChildOfClass("Model"):FindFirstChildOfClass("Humanoid"),"Outfits use standard Roblox rigs")
  captures.MaleFit(); assert(panel.ItemGallery:FindFirstChild("wear_club") and not panel.ItemGallery:FindFirstChild("wear_white_female"))
  captures.Paddles()
  captures.paddle_lotus(); assert(panel.FittingRoom.ItemName.Text=="Lotus Lake","Lotus print can be selected")
  captures.paddle_tour(); assert(panel.FittingRoom.ItemName.Text=="Catnap Club","Original cat replaces the removed design")
  captures.paddle_prism(); current.balance=0; publish(false); assert(not panel.FittingRoom.ItemAction.Active and panel.FittingRoom.ItemAction.Text=="INSUFFICIENT XP")
  camera.ViewportSize=Vector2.new(390,844); render:Fire(0.016)
  assert(panel.Size.X.Offset<=366 and panel.FittingRoom.Position.Y.Offset>panel.ItemGallery.Position.Y.Offset,"Phone layout stacks gallery and fitting room")
  camera.ViewportSize=Vector2.new(844,390); render:Fire(0.016)
  assert(panel:FindFirstChildOfClass("UIScale").Scale<1,"Short viewports fit without cropping")
  captures.CloseShop(); assert(not attributes.ShopOpen)
  publish(true); assert(not attributes.ShopOpen,"A closed token cannot reopen via stale traffic")
  revision+=1; remote.OnClientEvent:Fire({revision=revision,open=true,token="window-2",ack=requests[#requests].id,ready=false,inventory={},equipped={},error="Store unavailable"})
  assert(attributes.ShopOpen and not panel.FittingRoom.ItemAction.Active and panel.ShopFeedback.Text=="Store unavailable")
  captures.RetryShop(); assert(requests[#requests].action=="Retry")
 end)
 folder:Destroy(); assert(ok,err)
 return "Real previews in three categories, confirmation, buy/equip/unequip, separate balances, phone/landscape layout, stale windows and outage Retry passed"
end
