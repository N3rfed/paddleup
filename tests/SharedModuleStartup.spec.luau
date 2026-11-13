-- Existing Studio places may have Shared but lack new Rojo project mappings.
return function(serverSource,clientSource)
 local first=assert(serverSource:find('local shared=ReplicatedStorage:FindFirstChild("Shared")',1,true))
 local last=assert(serverSource:find("local CourtSession=",first,true))
 local storage=Instance.new("Folder")
 local server=Instance.new("Folder")
 local rules=Instance.new("ModuleScript"); rules.Name="MatchRules"; rules.Parent=server
 local setup=Instance.new("ModuleScript"); setup.Name="MatchSetup"; setup.Parent=server
 local cosmetics=Instance.new("Folder"); cosmetics.Name="Cosmetics"; cosmetics.Parent=server
 for _,name in ipairs({"CosmeticCatalog","CosmeticAssets"}) do
  local source=Instance.new("ModuleScript"); source.Name=name; source.Parent=cosmetics
 end
 local environment=setmetatable({ReplicatedStorage=storage,script=server},{__index=getfenv()})
 local loader=assert(loadstring(serverSource:sub(first,last-1)))
 setfenv(loader,environment)
 local ok,result=pcall(function()
  loader()
  local shared=assert(storage:FindFirstChild("Shared"))
  local published=assert(shared:FindFirstChild("MatchSetup"),"Server publishes missing menu rules")
  assert(shared:FindFirstChild("MatchRules"),"Existing rule fallback is preserved")
  local catalog=assert(shared:FindFirstChild("CosmeticCatalog"),"A missing shop catalog must not block check-in startup")
  local assets=assert(shared:FindFirstChild("CosmeticAssets"),"Shop visual assets are published before dependent services")
  assert(catalog~=cosmetics.CosmeticCatalog and assets~=cosmetics.CosmeticAssets,"Server templates stay intact")
  loader()
  assert(shared.CosmeticCatalog==catalog and shared.CosmeticAssets==assets,"Existing cosmetic mappings are reused")
  assert(shared:FindFirstChild("MatchSetup")==published and #shared:GetChildren()==4,"Existing mappings are reused")
  local menu=assert(clientSource:find('require(script:WaitForChild("MainMenu")).start(player,network)',1,true))
  local waitForSetup=assert(clientSource:find('WaitForChild("MatchSetup")',1,true))
  assert(menu<waitForSetup,"Menu starts before waiting on shared gameplay rules")
  return "Missing shared modules are published, existing mappings reused, and menu starts before gameplay rule waits"
 end)
 storage:Destroy(); server:Destroy()
 assert(ok,result)
 return result
end
