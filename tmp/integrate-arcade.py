from pathlib import Path
p=Path('src/server/init.server.luau');s=p.read_text()
def replace(a,b):
 global s
 assert a in s,a[:100]
 s=s.replace(a,b,1)
replace('local courtVariant=nil','local arcade=require(script:WaitForChild("ArcadePowers")).new()\narcade:reset()\nlocal arcadeRemote=remote("Arcade")\nlocal courtVariant=nil')
replace('if courtModifier~="LowGravity" or users[player].side==0 then clearEnvironmentGravity(player); return end','local factor=(courtModifier=="LowGravity" and 0.5 or 1)*arcade:gravity(os.clock())\n if factor==1 or users[player].side==0 then clearEnvironmentGravity(player); return end')
replace('root.AssemblyMass*workspace.Gravity*0.5','root.AssemblyMass*workspace.Gravity*(1-factor)')
replace('draft=nil; draftDue=courtVariant=="Chaos"; rallies=0','draft=nil; draftDue=courtVariant=="Chaos"; rallies=0\n arcade:reset()')
replace('local card=Powerups.choose(offer,id,d.powerups)','local card,slot\n if courtVariant=="Arcade" then card,slot=arcade:choose(p,offer,id,os.clock())\n else card=Powerups.choose(offer,id,d.powerups) end')
replace('table.insert(d.powerupNames,card.name)','if courtVariant=="Arcade" then\n  powerupRemote:FireClient(p,{kind="chosen",mode="Arcade",name=card.name,card=card,slot=slot}); return\n end\n table.insert(d.powerupNames,card.name)')
replace('local tier,offers=Powerups.deal(powerupRandom,#roster,builds)','local tier,offers=1,{}\n  if courtVariant=="Arcade" then\n   for index,p in ipairs(roster) do offers[index]=arcade:offer(p,users[p].arcadeDeck,now) end\n  else tier,offers=Powerups.deal(powerupRandom,#roster,builds) end')
replace('for index,p in ipairs(roster) do\n   draft.offers[p]=offers[index]','for index,p in ipairs(roster) do\n   if not offers[index] then continue end\n   draft.offers[p]=offers[index]')
replace('{kind="offer",id=draft.id,tier=tier,cards=offers[index]','{kind="offer",mode=courtVariant,id=draft.id,tier=tier,cards=offers[index]')
replace('return ball.p+Vector3.new(ball.v.X*t,-h,ball.v.Z*t),t','return ball.p+Vector3.new(ball.v.X*t+0.5*(ball.curveX or 0)*t*t,-h,ball.v.Z*t),t')
replace('local gravity=GRAVITY\n local duration=', 'local gravity=GRAVITY*arcade:gravity(os.clock())\n local duration=')
# Lob solver must use the same reduced gravity as the flight.
start=s.index('local function launch(');end=s.index('local function point(',start)
chunk=s[start:end].replace('Rules.lobLaunchY(from.Y-FLOOR,duration,GRAVITY)','Rules.lobLaunchY(from.Y-FLOOR,duration,gravity)').replace('Vector3.new(0,vy,0),GRAVITY,','Vector3.new(0,vy,0),gravity,')
# Compensate lateral acceleration so the curved shot still lands in the intended corner.
chunk=chunk.replace('ball.launchPosition=from;', 'ball.curveX=contact and contact.heatseeker and math.sign(target.X-from.X)*18 or 0\n ball.v-=Vector3.new(0.5*ball.curveX*duration/multiplier,0,0)\n ball.arcadeGravity=arcade:gravity(os.clock())\n ball.launchPosition=from;')
s=s[:start]+chunk+s[end:]
replace('elseif rallies%3==0 then draftDue=true end\n end\nend\nlocal function paddle', 'elseif rallies%3==0 then draftDue=true end\n elseif courtVariant=="Arcade" then\n  if ball.resetScore then resetPowerups() elseif arcade:rally() then draftDue=true end\n end\nend\nlocal function paddle')
replace('local function suspendPracticeTimers(dt)\n nextServe+=dt','local function suspendPracticeTimers(dt)\n arcade:pause(dt)\n nextServe+=dt')
replace('local reach=(1+((d.powerups and d.powerups.reach) or 0)+bonus)*(Comeback.active(comeback,d.side) and Comeback.HIT or 1)','local reach=(1+((d.powerups and d.powerups.reach) or 0)+bonus)*(Comeback.active(comeback,d.side) and Comeback.HIT or 1)*arcade:reach(p,now)')
replace('d.lastSwing=clean and now or now+Rules.HIT_COOLDOWN\n  p.Character:SetAttribute("HitReadyAt",workspace:GetServerTimeNow()+(clean and 0 or Rules.HIT_COOLDOWN))','local cooldown=Rules.HIT_COOLDOWN*(arcade:effect(p,"speedCleats",now) and ArcadeDeck.SPEED_SWING_SCALE or 1)\n  d.lastSwing=clean and now or now+cooldown\n  p.Character:SetAttribute("HitReadyAt",workspace:GetServerTimeNow()+(clean and 0 or cooldown))')
replace('ball.last=d.side; lastHitter[d.side]=p\n  launch(', 'ball.last=d.side; lastHitter[d.side]=p\n  local positions={}\n  for _,opponent in ipairs(teamPlayers(-d.side)) do local root=rootOf(opponent); if root then table.insert(positions,root.Position) end end\n  if courtMode=="Practice" then table.insert(positions,Vector3.new(botX,184,botZ)) end\n  local heatTarget=arcade:heatTarget(p,now,positions,d.side)\n  if heatTarget then target=heatTarget; quality="perfect"; soft=nil; slam=false end\n  launch(')
replace('{userId=p.UserId,clean=clean,\n   reflectedSpeed=', '{userId=p.UserId,clean=clean,heatseeker=heatTarget~=nil,\n   reflectedSpeed=')
# Dedicated slot activation: never trust client card IDs or effects.
replace('input.OnServerEvent:Connect(function(p,action,moveIntent)', '''arcadeRemote.OnServerEvent:Connect(function(p,index)
 local d=users[p]; local now=os.clock()
 if not d or d.side==0 or d.variant~="Arcade" or courtVariant~="Arcade" or practicePaused()
  or now<introUntil or draft or draftDue or not ball.live or p:GetAttribute("LeaveConfirmationOpen") then return end
 local root,humanoid=rootOf(p)
 if not root or not humanoid or humanoid.Health<=0 then return end
 local opponents=teamPlayers(-d.side)
 if courtMode=="Practice" then table.insert(opponents,"PracticeBot") end
 local card=arcade:activate(p,index,now,d.side,opponents,root,world)
 if card then tell(p,card.name:upper(),"perfect") end
end)
input.OnServerEvent:Connect(function(p,action,moveIntent)''')
replace('if paused then suspendPracticeTimers(dt) else updateDraft(now) end','''if paused then suspendPracticeTimers(dt) else updateDraft(now); arcade:update(now) end
 local gravityFactor=arcade:gravity(now)
 if ball.live and gravityFactor~=(ball.arcadeGravity or 1) then
  ball.flightGravity=(ball.flightGravity or GRAVITY)*gravityFactor/(ball.arcadeGravity or 1)
  ball.arcadeGravity=gravityFactor
 end''')
replace('local stunned=now<effect.stunUntil','''movement*=arcade:effect(p,"speedCleats",now) and 1.4 or 1
   local sliding,slideDirection=false,nil
   if d.side~=0 then sliding,slideDirection=arcade:touch(p,d.side,r.Position,now) end
   local stunned=now<effect.stunUntil or sliding''')
replace('if stunned then r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0) end','if stunned then r.AssemblyLinearVelocity=Vector3.new(0,r.AssemblyLinearVelocity.Y,0)+(sliding and slideDirection*16 or Vector3.zero) end')
replace('face.Material=fire and', 'face.Size=Vector3.new(1.65,2,0.3)*arcade:reach(p,now)\n    face.Material=fire and')
replace('local previous=ball.p\n   ball.p,ball.v,ball.g=Rules.advanceFlight', 'local previous=ball.p\n   local curve=ball.curveX or 0\n   ball.p+=Vector3.new(0.5*curve*step*step,0,0)\n   ball.p,ball.v,ball.g=Rules.advanceFlight')
replace('if previous.Z*ball.p.Z<=0', 'ball.v+=Vector3.new(curve*step,0,0)\n   if previous.Z*ball.p.Z<=0')
replace('elseif ball.p.Y<=FLOOR then\n    local fraction=', 'elseif ball.p.Y<=FLOOR then\n    ball.curveX=0\n    local fraction=')
replace('if now<botStunUntil then move=0 end','local botSliding=arcade:touch("PracticeBot",-1,Vector3.new(botX,184,botZ),now)\n  if now<botStunUntil or botSliding then move=0 end')
replace('distance<6.5*(Comeback.active(comeback,-1) and Comeback.HIT or 1)', 'distance<6.5*(Comeback.active(comeback,-1) and Comeback.HIT or 1)*arcade:reach("PracticeBot",now)')
replace('botPaddle.CFrame=CFrame.new', 'botPaddle.Size=Vector3.new(1.65,2,0.3)*arcade:reach("PracticeBot",now)\n botPaddle.CFrame=CFrame.new')
replace('practice=practiceState,practicePaused=paused,','practice=practiceState,practicePaused=paused,\n    arcade=d.side~=0 and courtVariant=="Arcade" and arcade:snapshot(p,now) or nil,curveX=ball.curveX,')
p.write_text(s)
p=Path('src/client/init.client.luau');s=p.read_text().replace('require(script:WaitForChild("HowToPlay")).start(player,network)','require(script:WaitForChild("HowToPlay")).start(player,network)\nrequire(script:WaitForChild("ArcadeSlots")).start(player,network)')
s=s.replace('elseif key.KeyCode==Enum.KeyCode.Q then input:FireServer("Power")','elseif key.KeyCode==Enum.KeyCode.Q and player:GetAttribute("MatchVariant")~="Arcade" then input:FireServer("Power")').replace('elseif key.KeyCode==Enum.KeyCode.E then input:FireServer("Slow")','elseif key.KeyCode==Enum.KeyCode.E and player:GetAttribute("MatchVariant")~="Arcade" then input:FireServer("Slow")')
a='else predicted=snapshot.p+snapshot.v*age end';print('prediction fallback',a in s)
# Insert after the prediction branch rather than changing shared flight helpers.
a='if Rules then predicted=Rules.advanceFlight';start=s.index(a);end=s.index('\n',s.index('else',start));print(s[start:end+1])
p.write_text(s)
