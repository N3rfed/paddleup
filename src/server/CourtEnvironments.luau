-- Swap only scenery. Keep the live court, net, ball, players, and physics intact.
local Environments={}
Environments.__index=Environments
local shared={
 ["Roof deck"]=true,["Court surround"]=true,["Playing surface"]=true,Kitchen=true,
 Sideline=true,["Court line"]=true,["Service center line"]=true,["Net post"]=true,
 ["Net collision"]=true,["Net white tape"]=true,["Net cord"]=true,RallyLights=true,
}
function Environments.valid(name) return name=="Rooftop" or name=="Moon" end
function Environments.new(root,height,preview)
 height=height or 0
 root:SetAttribute("CourtHeight",height)
 local self=setmetatable({root=root,active="Rooftop",colors={},height=height,destroyed=false},Environments)
 local cache=Instance.new("Folder"); cache.Name="CourtEnvironmentCache"; cache.Parent=game:GetService("ServerStorage")
 self.cache=cache
 local rooftop=Instance.new("Model"); rooftop.Name="RooftopEnvironment"
 for _,item in ipairs(root:GetChildren()) do
  if not shared[item.Name] then item.Parent=rooftop
  elseif item:IsA("BasePart") then self.colors[item]={color=item.Color,material=item.Material} end
 end
 rooftop.Parent=root; self.rooftop=rooftop
 root:SetAttribute("Environment","Rooftop"); root:SetAttribute("EnvironmentTitle","SKYLINE CLUB")

 -- Build once while players browse the lobby, before the first moon admission.
 self.previewTask=task.defer(function()
  if self.destroyed then return end
  if preview then
   self:moonModel()
   require(script.Parent:WaitForChild("MapPreviews")).publish(self.root,self.rooftop,self.moon)
  end
 end)
 return self
end
function Environments:moonModel()
 if self.moon then return self.moon end
 self.moon=require(script.Parent:WaitForChild("MoonEnvironment")).build()
 for _,part in ipairs(self.moon:GetDescendants()) do
  if part:IsA("BasePart") then part.CFrame=CFrame.new(0,self.height,0)*part.CFrame end
 end
 self.moon.Parent=self.cache
 return self.moon
end
function Environments:destroy()
 self.destroyed=true
 if self.previewTask and coroutine.status(self.previewTask)~="dead" then pcall(task.cancel,self.previewTask) end
 self.cache:Destroy()
end
function Environments:set(name)
 assert(Environments.valid(name),"Unknown court environment")
 if name==self.active then return end
 if name=="Moon" then
  self:moonModel()
  self.rooftop.Parent=self.cache; self.moon.Parent=self.root
 else
  if self.moon then self.moon.Parent=self.cache end
  self.rooftop.Parent=self.root
 end
 for part,original in pairs(self.colors) do
  if name=="Rooftop" then part.Color=original.color; part.Material=original.material
  elseif part.Name=="Roof deck" then part.Color=Color3.fromRGB(72,82,98); part.Material=Enum.Material.Metal
  elseif part.Name=="Court surround" then part.Color=Color3.fromRGB(48,59,77)
  elseif part.Name=="Playing surface" then part.Color=Color3.fromRGB(48,89,107)
  elseif part.Name=="Kitchen" then part.Color=Color3.fromRGB(57,127,140) end
 end
 self.active=name
 self.root:SetAttribute("Environment",name)
 self.root:SetAttribute("EnvironmentTitle",name=="Moon" and "SELENE LUNAR OUTPOST" or "SKYLINE CLUB")

end
return Environments
