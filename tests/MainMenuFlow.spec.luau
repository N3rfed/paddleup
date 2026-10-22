return function(Flow)
 local receive
 local signal={Connect=function(_,callback) receive=callback end}
 local queue={OnClientEvent=signal}
 function queue:FireServer() end
 local network={Session=queue}
 function network:WaitForChild(name) assert(name=="Queue"); return queue end
 local panel=Instance.new("Frame")
 local status=Instance.new("TextLabel")
 local heading=Instance.new("TextLabel",panel); heading.Name="Heading"
 local step=Instance.new("TextLabel",panel); step.Name="Step"
 local self={DisplayName="Guest"}
 local other={DisplayName="Other Player"}
 local ok,result=pcall(function()
  Flow.start(self,network,panel,status)
  assert(panel:FindFirstChild("Classic") and panel:FindFirstChild("Arcade") and panel:FindFirstChild("Chaos"),"Mode comes first")
  assert(not panel:FindFirstChild("1V1"),"Player counts are on the next screen")
  local now=workspace:GetServerTimeNow()
  local data={stage="Setup",mode="Classic",format="1V1",count=2,required=2,endsAt=now+15,
   counts={Rooftop=1,Moon=1},modifier="None",roster={
    {player=other,name=other.DisplayName,map="Rooftop",modifier="None"},
    {player=self,name=self.DisplayName,map="Moon",modifier="None"}}}
  receive(data)
  local moon=panel.Moon
  assert(moon.Selectable and panel.Rooftop.Selectable and not panel:FindFirstChild("StartMatch"),"Everyone votes; no host start button")
  assert(panel.Rooftop.Voters:FindFirstChild("Other Player"),"Opponent head appears under their chosen map")
  assert(moon.Voters:FindFirstChild("Guest") and moon.Selection.Visible,"Own head and choice are highlighted")
  assert(panel.Moon:FindFirstChild("MapImage") and panel.Rooftop:FindFirstChild("MapImage"),"Each map has a scenery thumbnail")
  assert(step.Text:find("VOTE CLOSES IN",1,true),"Voting countdown is visible")
  data.roster[1].map="Moon"; data.counts={Rooftop=0,Moon=2}; receive(data)
  assert(panel.Moon==moon and moon.Detail.Text:find("2 VOTES",1,true),"Live updates preserve map controls and update counts")
  assert(moon.Voters:FindFirstChild("Other Player") and not panel.Rooftop.Voters:FindFirstChild("Other Player"),"Changing maps moves the voter head")
  local otherVote=table.remove(data.roster,1)
  data.counts.Moon=1; receive(data)
  assert(not moon.Voters:FindFirstChild("Other Player"),"Departed voters are removed")
  table.insert(data.roster,1,otherVote); data.counts.Moon=2; receive(data)
  assert(not panel:FindFirstChild("LowGravity"),"Classic has no modifier")
  data.mode="Arcade"; receive({stage="Cancelled"}); receive(data)
  assert(panel.LowGravity.Selectable,"Every Arcade player can toggle their modifier vote")
  data.mode="Chaos"; data.modifier="LowGravity"; data.roster[2].modifier="LowGravity"
  receive({stage="Cancelled"}); receive(data)
  assert(not panel.LowGravity.Selectable and panel.LowGravity.Title.Text:find("ON",1,true),"Chaos modifier stays required")
  data.stage="Reveal"; data.candidates={"Rooftop","Moon"}; data.map="Moon"; data.revealAt=now; data.revealEndsAt=now+4
  receive(data)
  assert(not panel.Moon.Selectable and not panel.Rooftop.Selectable,"Reveal locks map inputs")
  assert(step.Text=="TIE / RANDOM DRAW","Ties show a roulette reveal")
  data.revealAt=now-4; data.revealEndsAt=now; receive(data)
  assert(step.Text=="MOON SELECTED" and panel.Moon.Accent.Thickness==3,"Reveal lands on the server's chosen map")
  receive({stage="Cancelled"})
  assert(panel:FindFirstChild("Classic") and not panel:FindFirstChild("Moon"),"Cancellation returns to modes")
  return "Mode-first menu, live opponent picks, persistent cards, countdown, modifiers, roulette, and cancellation passed"
 end)
 panel:Destroy(); status:Destroy()
 assert(ok,result)
 return result
end
