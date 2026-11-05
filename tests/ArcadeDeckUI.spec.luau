return function(UI)
 local folder=Instance.new("Folder")
 local player={WaitForChild=function(_,name) assert(name=="PlayerGui"); return folder end}
 local gui
 local ok,err=pcall(function()
  gui=UI.open(player,function() error("Cannot confirm an empty deck") end,function() end)
  local canvas=gui.TextButton.Frame
  assert(canvas.EnterMatch.Position.X.Offset+canvas.EnterMatch.Size.X.Offset/2==960,"Enter Match is centered")
  assert(not canvas.EnterMatch.Active and not canvas.EnterMatch.Selectable)
  local count=0
  for _,child in ipairs(canvas:GetChildren()) do
   if child:IsA("TextButton") and child:FindFirstChild("Content") then
    count+=1
    assert(not child:GetAttribute("Selected") and not child.Content.SelectedArt.Visible)
    assert(child.Size.X.Offset>=340,"Cards are large enough to read")
    local description,action=child.Content.Description,child.Content.CardAction
    assert(description.TextSize>=38 and not description.TextWrapped,"Short blurbs use a large, single-line font")
    assert(description.Position.Y.Offset+description.Size.Y.Offset+12<=action.Position.Y.Offset,"Descriptions have a clear gap above Select")
    assert(action.TextSize>=32,"Select remains readable")
    local words=0
    for _ in child.Content.Description.Text:gmatch("%S+") do words+=1 end
    assert(words==3,"Card blurbs contain exactly three words")
   end
  end
  assert(count==8 and not canvas:FindFirstChild("SelectedCount"))
  assert(canvas.speedCleats.Position.Y.Offset<canvas.slipStream.Position.Y.Offset,"Four cards per row")
 end)
 folder:Destroy()
 assert(ok,err)
end
