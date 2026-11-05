return function(Build,Deck)
 local card=Deck.chaosCard("dropPickles",0)
 local current,nextEffect,help=Build.details(card)
 assert(current:find("opponent",1,true) and current:find("12.5",1,true) and current:find("slip",1,true),"Current effect explains where, when and what happens")
 assert(nextEffect:find("11.0",1,true) and help:find("next upgrade choice",1,true),"Next level and how to obtain it are explicit")
 local _,maxed,maxHelp=Build.details(Deck.chaosCard("dropPickles",4))
 assert(maxed:find("fully upgraded",1,true) and maxHelp=="Maximum level reached.")
 local folder=Instance.new("Folder")
 local power,state=Instance.new("BindableEvent"),Instance.new("BindableEvent")
 local attrs={MatchVariant="Chaos"}
 local player={WaitForChild=function() return folder end,GetAttribute=function(_,key) return attrs[key] end,SetAttribute=function(_,key,value) attrs[key]=value end}
 local network={WaitForChild=function(_,key) return {OnClientEvent=key=="Powerup" and power.Event or state.Event} end}
 local controller=Build.start(player,network)
 local ok,result=pcall(function()
  power:Fire({kind="chosen",mode="Chaos",card=card,stats={dropPickles=1}})
  task.wait()
  controller.setOpen(true); task.wait(0.05)
  local panel=folder.PowerupBuild.BuildPanel
  assert(panel.Visible and panel.SelectedPowerup.Text=="Drop Pickles")
  assert(panel.PowerupList:FindFirstChild("Drop Pickles"),"Powerup navigation has named rows")
  assert(panel.UpgradeHelp.Text:find("next upgrade choice",1,true),"Inspecting a power does not claim to level it up")
  local currentLabel=panel:FindFirstChild("CurrentEffect",true)
  local nextLabel=panel:FindFirstChild("NextEffect",true)
  assert(currentLabel.Text==current and nextLabel.Text==nextEffect)
  assert(currentLabel.Parent.Position.Y.Offset+currentLabel.Parent.Size.Y.Offset<=nextLabel.Parent.Position.Y.Offset,"Current and next effects have separate sections")
  power:Fire({kind="chosen",mode="Chaos",card=Deck.chaosCard("dropPickles",1),stats={dropPickles=2}})
  task.wait(0.05)
  assert(currentLabel.Text:find("11.0",1,true),"Repeating a pick refreshes the explanation")
  power:Fire({kind="reset"}); task.wait()
  assert(not panel.Visible and not attrs.PowerupDetailsOpen,"Match reset closes and clears the build")
  return "Plain descriptions, next-level comparison, named navigation, upgrade updates and reset passed"
 end)
 controller.destroy(); folder:Destroy(); power:Destroy(); state:Destroy()
 assert(ok,result); return result
end
