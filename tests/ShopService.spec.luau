return function(source,Rules,Catalog,Assets)
 local function signal()
  local callbacks={}; local s={}
  function s:Connect(fn) table.insert(callbacks,fn); return {Disconnect=function() end} end
  function s:Fire(...) for _,fn in ipairs(callbacks) do fn(...) end end
  return s
 end
 local clock=0; local players={PlayerRemoving=signal()}; local packets={}; local remote={OnServerEvent=signal()}
 function remote:FireClient(player,data) packets[player]=data end
 local network=Instance.new("Folder"); local lobby=Instance.new("Model")
 local counter=Instance.new("Part"); counter.Name="Boutique stone top"; counter.Anchored=true; counter.Parent=lobby
 local character=Instance.new("Model"); local root=Instance.new("Part"); root.Name="HumanoidRootPart"; root.Anchored=true; root.Parent=character
 local h=Instance.new("Humanoid"); h.Parent=character
 local mode="Lobby"; local player={UserId=1,Parent=players,Character=character,GetAttribute=function() return mode end}
 local record=Rules.new(); record.totalXP=1000; record.spendableXP=1000
 local callbacks={}; local count=0; local fail=false
 local progression={entries={[player]={player=player,data=record,queue={},running=false,failed=false}}}
 function progression:subscribe(callback) table.insert(callbacks,callback) end
 function progression:refreshShop() end
 function progression:shop(p,kind,item,category)
  if fail then return false end
  count+=1; local entry=self.entries[p]
  local data,result=Rules.apply(entry.data,{kind=kind,item=item,category=category,id="service-shop-"..count,at=20000*86400+clock},20000*86400+clock)
  entry.data=data; entry.shopResult=result
  for _,callback in ipairs(callbacks) do callback(entry) end
  return true
 end
 local captures={}; local guid=0
 local shared={WaitForChild=function(_,name) return name end}
 local services={ReplicatedStorage={WaitForChild=function() return shared end},Players=players,HttpService={GenerateGUID=function() guid+=1; return "token-"..guid end}}
 local instanceProxy={new=function(class) if class=="RemoteEvent" then return remote end; return Instance.new(class) end}
 local instrumented=source:gsub("prompt%.Triggered:Connect%(function%(player%)","capturePrompt(function(player)")
 local fn=assert(loadstring(instrumented))
 setfenv(fn,setmetatable({Instance=instanceProxy,os={clock=function() return clock end},script={Parent={WaitForChild=function(_,name) return name end}},
  require=function(name) return assert(({CosmeticCatalog=Catalog,CosmeticAssets=Assets,ProgressionRules=Rules})[name],name) end,
  capturePrompt=function(callback) captures.prompt=callback end,game={GetService=function(_,name) return assert(services[name],name) end}},{__index=getfenv()}))
 local ok,err=pcall(function()
  local service=fn().start(network,lobby,progression)
  assert(service.prompt.KeyboardKeyCode==Enum.KeyCode.E and service.near(player))
  mode="Practice"; captures.prompt(player); assert(not packets[player],"Shop can only open from lobby")
  mode="Lobby"; captures.prompt(player); local token=packets[player].token; assert(packets[player].open and token)
  local function request(action,id,value,key) clock+=1; remote.OnServerEvent:Fire(player,action,id,key or token,value) end
  request("Buy",1,"paddle_porcelain","stale-token"); assert(count==0)
  request("Buy",2,{id="paddle_porcelain",price=0}); assert(count==0,"Client price and ownership payloads are rejected")
  request("Buy",3,"missing"); assert(count==0)
  request("Buy",4,"paddle_porcelain"); assert(count==1 and progression.entries[player].data.inventory.paddle_porcelain)
  local balance=progression.entries[player].data.spendableXP
  request("Buy",4,"paddle_porcelain"); assert(count==1,"Repeated request ID is ignored")
  request("Buy",5,"paddle_porcelain"); assert(progression.entries[player].data.spendableXP==balance,"New IDs cannot charge for owned items")
  local before=count
  remote.OnServerEvent:Fire(player,"Buy",6,token,"paddle_noir"); assert(count==before,"Rapid repeated events are rate limited")
  request("Equip",7,"paddle_porcelain"); assert(progression.entries[player].data.equipped.Paddles=="paddle_porcelain")
  request("Unequip",8,"Paddles"); assert(not progression.entries[player].data.equipped.Paddles)
  root.Position=Vector3.new(100,0,0); request("Buy",9,"wear_headband"); assert(not progression.entries[player].data.inventory.wear_headband,"Distance is revalidated on every purchase")
  root.Position=Vector3.zero; fail=true; request("Buy",10,"wear_headband"); assert(progression.entries[player].data.spendableXP==balance)
  fail=false; clock=200; request("Buy",11,"wear_headband"); assert(not progression.entries[player].data.inventory.wear_headband,"Expired sessions cannot purchase")
  clock+=2; captures.prompt(player); token=packets[player].token
  request("Close",12); request("Buy",13,"wear_headband"); assert(not progression.entries[player].data.inventory.wear_headband,"Closing invalidates interaction permission")
 end)
 character:Destroy(); lobby:Destroy(); network:Destroy(); assert(ok,err)
 return "Existing boutique E prompt, lobby/proximity checks, stale tokens, input allowlists, immutable server prices, duplicate/rate-limited requests, failed saves and expired sessions passed"
end
