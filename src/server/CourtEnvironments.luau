-- Swap only scenery. Keep the live court, net, ball, players, and physics intact.
local Environments={}
Environments.__index=Environments
local shared={
 ["Roof deck"]=true,["Court surround"]=true,["Playing surface"]=true,Kitchen=true,
 Sideline=true,["Court line"]=true,["Service center line"]=true,["Net post"]=true,
 ["Net collision"]=true,["Net white tape"]=true,["Net cord"]=true,RallyLights=true,
}
function Environments.valid(name) return name=="Rooftop" or name=="Moon" end
function Environments.new(root)
 local self=setmetatable({root=root,active="Rooftop",colors={}},Environments)
 local cache=Instance.new("Folder"); cache.Name="CourtEnvironmentCache"; cache.Parent=game:GetService("ServerStorage")
 self.cache=cache
 local rooftop=Instance.new("Model"); rooftop.Name="RooftopEnvironment"
 for _,item in ipairs(root:GetChildren()) do
  if not shared[item.Name] then item.Parent=rooftop
  elseif item:IsA("BasePart") then self.colors[item]={color=item.Color,material=item.Material} end
 end
 rooftop.Parent=root; self.rooftop=rooftop
 -- This adjacent rooftop building lives outside the main court model.
 self.rooftopHall=workspace:FindFirstChild("SkylineLobby")
 root:SetAttribute("Environment","Rooftop"); root:SetAttribute("EnvironmentTitle","SKYLINE CLUB")
 workspace:SetAttribute("CourtEnvironment","Rooftop")
 -- Build once while players browse the lobby, before the first moon admission.
 task.defer(function()
  if not self.moon then
   self.moon=require(script.Parent:WaitForChild("MoonEnvironment")).build()
   self.moon.Parent=self.cache
  end
  require(script.Parent:WaitForChild("MapPreviews")).publish(self.root,self.rooftop,self.moon)
 end)
 return self
end
function Environments:set(name)
 assert(Environments.valid(name),"Unknown court environment")
 if name==self.active then return end
 if name=="Moon" then
  self.moon=self.moon or require(script.Parent:WaitForChild("MoonEnvironment")).build()
  self.rooftop.Parent=self.cache; self.moon.Parent=self.root
  if self.rooftopHall then self.rooftopHall.Parent=self.cache end
 else
  if self.moon then self.moon.Parent=self.cache end
  self.rooftop.Parent=self.root
  if self.rooftopHall then self.rooftopHall.Parent=workspace end
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
 workspace:SetAttribute("CourtEnvironment",name)
end
return Environments
