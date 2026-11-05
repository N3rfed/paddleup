return function(Help)
 local root=Instance.new("Folder")
 local signal=Instance.new("BindableEvent")
 local attributes={SessionMode="Lobby"}
 local changed=Instance.new("BindableEvent")
 local player={WaitForChild=function() return root end,
  GetAttribute=function(_,name) return attributes[name] end,
  SetAttribute=function(_,name,value) attributes[name]=value end,
  GetAttributeChangedSignal=function() return changed.Event end}
 local network={WaitForChild=function() return {OnClientEvent=signal.Event} end}
 local ok,err=pcall(function()
  local help=Help.start(player,network)
  local gui=assert(root:FindFirstChild("HowToPlay"))
  assert(not help.isOpen() and not gui.Overlay.Visible)
  assert(not gui.HelpButton.Visible,"The lobby does not show an info button")
  help.setOpen(true)
  assert(not help.isOpen(),"The H shortcut cannot open instructions from the lobby")
  attributes.SessionMode="Practice"; changed:Fire(); task.wait()
  assert(gui.HelpButton.Visible,"The info button appears while playing")
  assert(gui.HelpButton.Position==UDim2.new(1,-52,0,16) and gui.HelpButton.Size==UDim2.fromOffset(36,36),"Compact help aligns beside the leave button")
  local outlines=0
  for _,child in ipairs(gui.HelpButton:GetChildren()) do
   if child.Name:match("^IconOutline") then outlines+=1; assert(child.ImageColor3==Color3.fromRGB(12,12,30)) end
  end
  assert(outlines==8 and gui.HelpButton.KeyHint:FindFirstChildOfClass("UIStroke"),"Icon and key label have black outlines")
  help.setOpen(true)
  assert(help.isOpen() and attributes.HowToPlayOpen and gui.Overlay.Visible)
  assert(gui.Overlay.Panel.Play.Selectable and gui.Overlay.Panel.Close.Selectable)
  assert(gui.Overlay.Panel.Figma_howToPlay.Image~="")
  help.setOpen(false)
  assert(not help.isOpen() and not attributes.HowToPlayOpen)
  signal:Fire({matchIntro={id=1}}); task.wait()
  help.setOpen(true)
  assert(not help.isOpen() and not gui.HelpButton.Visible,"Intro keeps the instructions closed")
  signal:Fire({}); task.wait()
  help.setOpen(true)
  attributes.PowerupDraftOpen=true; changed:Fire(); task.wait()
  assert(not help.isOpen(),"Starting a draft closes the instructions")
  attributes.PowerupDraftOpen=false; attributes.SessionMode="Spectate"; changed:Fire(); task.wait()
  assert(not gui.HelpButton.Visible,"Spectators are not playing")
  attributes.SessionMode="Lobby"; changed:Fire(); task.wait()
  assert(not gui.HelpButton.Visible and not help.isOpen(),"Returning to the lobby hides and closes help")
 end)
 root:Destroy(); signal:Destroy(); changed:Destroy()
 assert(not attributes.HowToPlayOpen,"Destroying the GUI releases the input block")
 assert(ok,err)
end
