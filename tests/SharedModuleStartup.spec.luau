-- Existing Studio places may have Shared but lack new Rojo project mappings.
return function(serverSource,clientSource)
 local first=assert(serverSource:find('local shared=ReplicatedStorage:FindFirstChild("Shared")',1,true))
 local last=assert(serverSource:find("local CourtSession=",first,true))
 local storage=Instance.new("Folder")
 local server=Instance.new("Folder")
 local rules=Instance.new("ModuleScript"); rules.Name="MatchRules"; rules.Parent=server
 local setup=Instance.new("ModuleScript"); setup.Name="MatchSetup"; setup.Parent=server
 local environment=setmetatable({ReplicatedStorage=storage,script=server},{__index=getfenv()})
 local loader=assert(loadstring(serverSource:sub(first,last-1)))
 setfenv(loader,environment)
 local ok,result=pcall(function()
  loader()
  local shared=assert(storage:FindFirstChild("Shared"))
  local published=assert(shared:FindFirstChild("MatchSetup"),"Server publishes missing menu rules")
  assert(shared:FindFirstChild("MatchRules"),"Existing rule fallback is preserved")
  loader()
  assert(shared:FindFirstChild("MatchSetup")==published and #shared:GetChildren()==2,"Existing mappings are reused")
  local menu=assert(clientSource:find('require(script:WaitForChild("MainMenu")).start(player,network)',1,true))
  local waitForSetup=assert(clientSource:find('WaitForChild("MatchSetup")',1,true))
  assert(menu<waitForSetup,"Menu starts before waiting on shared gameplay rules")
  return "Missing shared modules are published, existing mappings reused, and menu starts before gameplay rule waits"
 end)
 storage:Destroy(); server:Destroy()
 assert(ok,result)
 return result
end
