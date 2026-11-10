return function(serverSource,clientSource,Assets)
 local function signal()
  local items={}; local s={}
  function s:Connect(fn) local c={Connected=true}; function c:Disconnect() self.Connected=false end; table.insert(items,{fn=fn,c=c}); return c end
  function s:Fire(...) for _,i in ipairs(items) do if i.c.Connected then i.fn(...) end end end
  return s
 end
 local roots={}
 local function rig()
  local c=Instance.new("Model"); table.insert(roots,c)
  for _,name in ipairs({"Head","UpperTorso","LeftHand","RightHand","PaddleFace"}) do
   local p=Instance.new("Part"); p.Name=name; p.Anchored=true; p.Parent=c
   if name=="PaddleFace" then p.Size=Vector3.new(1.65,2,0.3); p.Color=Color3.fromRGB(31,193,180) end
  end
  local shirt=Instance.new("Shirt"); shirt.Name="OriginalShirt"; shirt.Parent=c
  return c
 end
 local players={PlayerAdded=signal(),PlayerRemoving=signal()}; local list={}
 local function player()
  local attrs={}; local changed={}
  local p={Character=rig(),CharacterAdded=signal(),CharacterAppearanceLoaded=signal(),Parent=players}
  function p:SetAttribute(key,value) attrs[key]=value; if changed[key] then changed[key]:Fire() end end
  function p:GetAttribute(key) return attrs[key] end
  function p:GetAttributeChangedSignal(key) changed[key]=changed[key] or signal(); return changed[key] end
  table.insert(list,p); return p
 end
 local a,b=player(),player()
 function players:GetPlayers() return list end
 local shared={WaitForChild=function(_,name) return name end}
 local fn=assert(loadstring(serverSource))
 setfenv(fn,setmetatable({require=function() return Assets end,
  game={GetService=function(_,name) if name=="Players" then return players end return {WaitForChild=function() return shared end} end}},{__index=getfenv()}))
 local entries={
  [a]={player=a,data={equipped={Paddles="paddle_afterglow",Wearables="wear_club",Courts="court_arcade"}}},
  [b]={player=b,data={equipped={Paddles="paddle_noir",Wearables="wear_headband",Courts="court_noir"}}}}
 local observer
 local progression={subscribe=function(_,callback) observer=callback; for _,entry in pairs(entries) do callback(entry) end end}
 local ok,err=pcall(function()
  fn().start(progression); task.wait()
  assert(a.Character.PaddleFace.Color~=b.Character.PaddleFace.Color and a.Character.ShopWearable and b.Character.ShopWearable,"Different players wear their own real equipment simultaneously")
  assert(a:GetAttribute("EquippedCourt")=="court_arcade" and b:GetAttribute("EquippedCourt")=="court_noir")
  local previous=a.Character; a.Character=rig(); a.CharacterAdded:Fire(a.Character); task.wait()
  assert(a.Character.PaddleFace:FindFirstChild("ShopPaddleArt") and a.Character.ShopWearable,"Respawn reapplies saved cosmetics")
  a.Character.PaddleFace:Destroy()
  local face=Instance.new("Part"); face.Name="PaddleFace"; face.Size=Vector3.new(1.65,2,0.3); face.Color=Color3.fromRGB(31,193,180); face.Parent=a.Character; task.wait()
  assert(face:FindFirstChild("ShopPaddleArt"),"Court-created paddles receive equipped art")
  entries[a].data.equipped={}; observer(entries[a]); task.wait()
  assert(not face:FindFirstChild("ShopPaddleArt") and not a.Character:FindFirstChild("ShopWearable") and a.Character.OriginalShirt,"Unequip restores originals")
  -- Separate local workspaces represent independent clients viewing the same logical court slot.
  local worldA={}; local worldB={}
  local courtA=Assets.preview("court_classic"); courtA.Name="PaddleUpCourt1"; table.insert(roots,courtA); worldA.PaddleUpCourt1=courtA
  local courtB=Assets.preview("court_classic"); courtB.Name="PaddleUpCourt1"; table.insert(roots,courtB); worldB.PaddleUpCourt1=courtB
  Assets.court(courtA,nil); Assets.court(courtB,nil)
  local function client(p,world)
   world.DescendantAdded=signal(); function world:FindFirstChild(name) return self[name] end
   local chunk=assert(loadstring(clientSource))
   setfenv(chunk,setmetatable({workspace=world,require=function() return Assets end,
    game={GetService=function() return {WaitForChild=function() return shared end} end}},{__index=getfenv()}))
   p:SetAttribute("CourtId",1); p:SetAttribute("CourtSide",1)
   -- Detached test courts need a parent to model a streamed workspace.
   local holder=Instance.new("Folder"); table.insert(roots,holder); world.PaddleUpCourt1.Parent=holder
   chunk().start(p)
  end
  a:SetAttribute("EquippedCourt","court_tropical"); b:SetAttribute("EquippedCourt","court_noir")
  client(a,worldA); client(b,worldB); task.wait()
  assert(courtA["Playing surface"].Color~=courtB["Playing surface"].Color,"Same match slot renders independently on two clients")
  local bColor=courtB["Playing surface"].Color
  a:SetAttribute("EquippedCourt","court_modern"); task.wait(); assert(courtB["Playing surface"].Color==bColor)
  a:SetAttribute("CourtSide",0); task.wait(); assert(not courtA:FindFirstChild("ShopCourtArt"),"Leaving a match restores the original local surface")
 end)
 players.PlayerRemoving:Fire(a); players.PlayerRemoving:Fire(b)
 for _,root in ipairs(roots) do root:Destroy() end
 assert(ok,err)
 return "Simultaneous real equipment, respawn, recreated gameplay paddles, default avatar restoration, separate-client court themes and match exit passed"
end
