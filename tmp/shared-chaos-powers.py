from pathlib import Path
p=Path('src/server/ArcadePowers.luau');s=p.read_text().replace('-- Two server-owned consumable slots. Offers come only from the player\'s deck.','-- Shared eight-power engine: Arcade deck offers and random Chaos stacks.')
s=s.replace('{slots={},effects={}}','{slots={},effects={},pending={}}')
s=s.replace(' local slots=self:data(player).slots\n for index=1,2 do\n  if slots[index] and slots[index].readyAt and now>=slots[index].readyAt then slots[index]=nil end\n end',''' local data=self:data(player)
 local slots=data.slots
 for index=1,2 do
  local slot=slots[index]
  if slot and slot.readyAt and now>=slot.readyAt then
   if (slot.charges or 0)>0 then slot.readyAt=nil;slot.activeUntil=nil;slot.duration=nil
   else slots[index]=nil end
  end
  if not slots[index] and #data.pending>0 then
   local id=table.remove(data.pending,1);slots[index]={id=id,charges=1}
   for i=#data.pending,1,-1 do if data.pending[i]==id then slots[index].charges+=1;table.remove(data.pending,i) end end
  end
 end''')
s=s.replace('function Arcade:choose(player,offer,id,now)\n local index=self:empty(player,now)\n if not index or type(offer)~="table" then return nil end','''function Arcade:chaosOffer()
 local cards=table.clone(Deck.cards)
 for i=#cards,2,-1 do local j=self.random:NextInteger(1,i); cards[i],cards[j]=cards[j],cards[i] end
 return {cards[1],cards[2],cards[3]}
end
function Arcade:choose(player,offer,id,now,stack)
 local index=self:empty(player,now)
 if (not index and not stack) or type(offer)~="table" then return nil end''')
s=s.replace('   self:data(player).slots[index]={id=id}\n   return card,index','''   local data=self:data(player)
   if stack then
    for slot,existing in pairs(data.slots) do
     if existing.id==id then existing.charges=(existing.charges or 0)+1;return card,slot end
    end
   end
   if index then data.slots[index]={id=id,charges=1}
   else table.insert(data.pending,id) end
   return card,index''')
s=s.replace(' local data=self:data(player)\n local slot=data.slots[index]',' self:empty(player,now)\n local data=self:data(player)\n local slot=data.slots[index]')
s=s.replace(' local card=Deck.find(slot.id)\n local duration=',' local card=Deck.find(slot.id)\n slot.charges=math.max(0,(slot.charges or 1)-1)\n local duration=')
s=s.replace('slots[index]=slot and {id=slot.id,active=','slots[index]=slot and {id=slot.id,charges=slot.charges or 0,active=')
s=s.replace('return {slots=slots,glow=','return {slots=slots,queued=#self:data(player).pending,glow=')
p.write_text(s)
p=Path('src/server/init.server.luau');s=p.read_text()
a=s.index(' local card,slot\n',s.index('local function choosePowerup'));b=s.index('\nend\npowerupRemote.OnServerEvent',a)
s=s[:a]+''' local card,slot=arcade:choose(p,offer,id,os.clock(),courtVariant=="Chaos")
 if not card then return end
 draft.offers[p]=nil
 powerupRemote:FireClient(p,{kind="chosen",mode=courtVariant,sharedPowers=true,name=card.name,card=card,slot=slot})'''+s[b:]
a=s.index('  local builds={}\n',s.index('local function updateDraft'));b=s.index('  draftSerial+=1',a)
s=s[:a]+'''  local offers={}
  for index,p in ipairs(roster) do
   offers[index]=courtVariant=="Chaos" and arcade:chaosOffer() or arcade:offer(p,users[p].arcadeDeck,now)
  end
'''+s[b:]
s=s.replace('id=draft.id,tier=tier,cards=offers[index]','id=draft.id,sharedPowers=true,cards=offers[index]')
s=s.replace('d.variant~="Arcade" or courtVariant~="Arcade"','(d.variant~="Arcade" and d.variant~="Chaos") or (courtVariant~="Arcade" and courtVariant~="Chaos")')
s=s.replace('arcade=d.side~=0 and courtVariant=="Arcade" and arcade:snapshot(p,now)','arcade=d.side~=0 and (courtVariant=="Arcade" or courtVariant=="Chaos") and arcade:snapshot(p,now)')
p.write_text(s)
p=Path('src/client/ArcadeSlots.luau');s=p.read_text().replace('player:GetAttribute("MatchVariant")=="Arcade"','(player:GetAttribute("MatchVariant")=="Arcade" or player:GetAttribute("MatchVariant")=="Chaos")')
s=s.replace('  label(content,"Key",key,44,79,22,18,17)','  local count=label(content,"Charges","",72,20,25,16,11)\n  label(content,"Key",key,44,79,22,18,17)')
s=s.replace('timer=timer,status=status,segments=segments','timer=timer,status=status,count=count,segments=segments')
s=s.replace('   view.status.Text=mode;','   view.count.Text=(slot.charges or 0)>1 and ("x"..slot.charges) or ""\n   view.status.Text=mode;')
p.write_text(s)
p=Path('src/client/init.client.luau');s=p.read_text().replace('player:GetAttribute("MatchVariant")~="Arcade" then input:FireServer','player:GetAttribute("MatchVariant")~="Arcade" and player:GetAttribute("MatchVariant")~="Chaos" then input:FireServer');p.write_text(s)
p=Path('src/client/PowerupBuild.luau');s=p.read_text().replace('and data.mode~="Arcade" then','and data.mode~="Arcade" and not data.sharedPowers then');p.write_text(s)
p=Path('src/client/PowerupDraft.luau');s=p.read_text().replace('local color=colors[data.tier]','local color=Color3.fromRGB(80,232,255)')
s=s.replace('subtitle.Text=names[data.tier].."  /  Choose one upgrade to keep this match"','subtitle.Text="CHOOSE A POWERUP"')
s=s.replace('-- Chaos shares the clean three-card artwork while keeping its stacking catalog.','-- Chaos draws the same eight powers without a preselected deck.')
s=s.replace('subtitle.Text=names[data.tier].."  /  CHOOSE ONE UPGRADE"','subtitle.Text="CHAOS  /  CHOOSE A POWERUP"')
s=s.replace('card.description,420,78,26','card.blurb,420,78,32')
s=s.replace('footer.Text=data.mode=="Arcade" and ("Equipped in "..(data.slot==1 and "Q" or "E")..". Waiting for the other players...") or "Upgrade locked in. Waiting for the other players..."','footer.Text=data.slot and ("Equipped in "..(data.slot==1 and "Q" or "E")..". Waiting for the other players...") or "Added to your powerup stack. Waiting for the other players..."')
s=s.replace(' local names={"SILVER","GOLD","PRISMATIC"}\n','').replace(' local colors={Color3.fromRGB(198,213,230),Color3.fromRGB(255,211,93),Color3.fromRGB(197,137,255)}\n','')
s=s.replace('A U G M E N T   D R A F T','C H A O S   P O W E R U P S').replace('CHOOSE YOUR EDGE','CHOOSE A POWERUP').replace('One upgrade. Yours for the match.','Choose from the same eight powerups.').replace('SHARED RARITY  /  PERSONAL OFFERS  /  MATCH-LONG EFFECTS','COLLECT POWERUPS  /  ACTIVATE WITH Q OR E')
p.write_text(s)
