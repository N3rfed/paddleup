local RematchUI={}

function RematchUI.start(player,network)
 local RunService=game:GetService("RunService")
 local session=network:WaitForChild("Session")
 local gui=Instance.new("ScreenGui")
 gui.Name="Rematch"; gui.ResetOnSpawn=false; gui.DisplayOrder=75
 gui.Parent=player:WaitForChild("PlayerGui")
 local panel=Instance.new("Frame",gui)
 panel.Name="Prompt"; panel.AnchorPoint=Vector2.new(0.5,1)
 panel.Position=UDim2.new(0.5,0,1,-55); panel.Size=UDim2.new(0.9,0,0,164)
 panel.BackgroundColor3=Color3.fromRGB(27,27,64); panel.Visible=false
 local limit=Instance.new("UISizeConstraint",panel); limit.MaxSize=Vector2.new(490,164)
 Instance.new("UICorner",panel).CornerRadius=UDim.new(0,14)
 local cream=Color3.fromRGB(246,246,255)
 local function label(name,text,y,height,size)
  local item=Instance.new("TextLabel",panel)
  item.Name=name; item.Position=UDim2.new(0,14,0,y); item.Size=UDim2.new(1,-28,0,height)
  item.BackgroundTransparency=1; item.Text=text; item.TextColor3=cream
  item.Font=Enum.Font.GothamBold; item.TextSize=size; item.TextWrapped=true
  return item
 end
 label("Question","Would you like to play another game?",9,52,20)
 local countdown=label("Countdown","",65,21,16)
 local vote,sessionId,submitted,leaving
 local function button(name,x,color,callback)
  local action=Instance.new("TextButton",panel)
  action.Name=name; action.Position=UDim2.new(x,12,0,101)
  action.Size=UDim2.new(0.5,-24,0,45); action.BackgroundColor3=color
  action.Text=name; action.Font=Enum.Font.GothamBold; action.TextSize=17
  action.TextColor3=Color3.fromRGB(22,22,49); action.Modal=true
  Instance.new("UICorner",action).CornerRadius=UDim.new(0,10)
  action.Activated:Connect(callback)
  return action
 end
 local play=button("Play Again",0,Color3.fromRGB(80,232,255),function()
  if not vote or submitted or leaving or workspace:GetServerTimeNow()>=vote.endsAt then return end
  submitted=true
  session:FireServer("RematchVote",vote.id,"PlayAgain",sessionId)
 end)
 local leave=button("Leave",0.5,Color3.fromRGB(245,150,178),function()
  if not vote or leaving or workspace:GetServerTimeNow()>=vote.endsAt then return end
  leaving=true
  session:FireServer("RematchVote",vote.id,"Leave",sessionId)
 end)
 local function clear()
  vote=nil; sessionId=nil; submitted=false; leaving=false
  panel.Visible=false; player:SetAttribute("RematchOpen",false)
 end
 player:GetAttributeChangedSignal("MatchSessionId"):Connect(clear)
 network:WaitForChild("State").OnClientEvent:Connect(function(state)
  if state.matchSessionId~=player:GetAttribute("MatchSessionId") then return end
  if not state.rematch then
   if vote then clear() end
   return
  end
  if not vote or vote.id~=state.rematch.id then clear() end
  vote=state.rematch; sessionId=state.matchSessionId
  panel.Visible=true; player:SetAttribute("RematchOpen",true)
 end)
 RunService.RenderStepped:Connect(function()
  if not vote then return end
  local remaining=math.max(0,math.ceil(vote.endsAt-workspace:GetServerTimeNow()))
  play.Interactable=not submitted and not vote.accepted and not leaving and remaining>0
  leave.Interactable=not leaving and remaining>0
  countdown.Text=remaining==0 and "Finishing vote…" or ((submitted or vote.accepted) and "Waiting for teammates and opponents · " or "")..remaining.."s"
 end)
end

return RematchUI
