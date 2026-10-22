-- Real environment routing with detached scenery and storage; no live DataModel changes.
return function(source)
 local storage=Instance.new("Folder")
 local roots={}
 local function root()
  local model=Instance.new("Model")
  local surface=Instance.new("Part"); surface.Name="Playing surface"; surface.Parent=model
  local scenery=Instance.new("Part"); scenery.Name="Scenery"; scenery.Parent=model
  table.insert(roots,model); return model
 end
 local chunk=assert(loadstring(source))
 local moon={build=function()
  local model=Instance.new("Model")
  local part=Instance.new("Part"); part.Position=Vector3.new(0,185,0); part.Parent=model
  return model
 end}
 setfenv(chunk,setmetatable({game={GetService=function() return storage end},
  script={Parent={WaitForChild=function(_,name) return name end}},require=function(name) assert(name=="MoonEnvironment"); return moon end}, {__index=getfenv()}))
 local Environments=chunk()
 local first,second=Environments.new(root(),4096,false),Environments.new(root(),8192,false)
 local ok,err=pcall(function()
  first:set("Moon")
  assert(first.root:GetAttribute("Environment")=="Moon" and second.root:GetAttribute("Environment")=="Rooftop")
  assert(first.moon:GetChildren()[1].Position.Y==4281,"Moon scenery follows its court height")
  second:set("Moon"); first:set("Rooftop")
  assert(second.moon.Parent==second.root and first.moon.Parent==first.cache,"Environment caches are independent")
 end)
 first:destroy(); second:destroy()
 assert(#storage:GetChildren()==0,"Environment caches are removed on shutdown")
 for _,model in ipairs(roots) do model:Destroy() end
 storage:Destroy()
 assert(ok,err)
 return "Independent map selection, translated Moon scenery, cache isolation, and cleanup passed"
end
