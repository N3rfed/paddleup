-- Small vector illustrations drawn with native UI primitives: no external assets.
local Art={}
local motifs={
 kitchenCamper="COURT",dinkSpecialist="TARGET",carbonFiber="PADDLE",secondServe="RESET",sliceDice="DIVE",
 thirdShot="TARGET",serveVolley="BOLT",vampiricReach="PADDLE",atpAssassin="APEX",baitSwitch="MASK",
 erne="APEX",phantom="CLONE",lava="BOLT",overcharge="BOLT",deflector="SHIELD",
 airTime="APEX",
}
local badges={
 kitchenCamper="+15% MOVE",dinkSpecialist="3 DINKS / +20%",carbonFiber="+15% SWEET SPOT",secondServe="1 FREE RETRY",sliceDice="10% LOWER BOUNCE",
 thirdShot="+40% ACCURACY",serveVolley="3 SECOND BURST",vampiricReach="UP TO +10% REACH",atpAssassin="30% STAMINA DAMAGE",baitSwitch="1 SECOND STUN",
 erne="300% POWER",phantom="+8 INCHES",lava="2x STAMINA DRAIN",overcharge="16 SHOTS / ON FIRE",deflector="2x RETURN VELOCITY",
 perfectVision="+20% TIMING WINDOW",quickRecovery="50% FASTER RECOVERY",baselineSentinel="+15% LATERAL SPEED",calculatedReturn="80% RETURN VELOCITY",
 momentumShift="3 PERFECT / +15%",offensiveDive="MAXIMUM TOPSPIN",kitchenWarden="+25% FORWARD REACH",deceptiveDrop="0.5s RETICLE DELAY",
 apexPredator="HEAVY / HIDDEN SPEED",rhythmMaster="11+ HITS / VANISH",afterimage="2s CLONE / DECOY",terminalVelocity="+8% / NO SPEED CAP",
 airTime="1 SECOND SLOW FALL",
}
function Art.badge(card)
 return badges[card.id] or string.format("+%d%% %s",math.floor((card.amount or 0)*100+0.5),(card.stat or "UPGRADE"):upper())
end
function Art.draw(parent,card,color)
 local function shape(x,y,w,h,rotation,alpha)
  local f=Instance.new("Frame"); f.BorderSizePixel=0; f.BackgroundColor3=color
  f.Size=UDim2.fromOffset(w,h); f.Position=UDim2.fromOffset(x,y); f.AnchorPoint=Vector2.new(0.5,0.5)
  f.Rotation=rotation or 0; f.BackgroundTransparency=alpha or 0; f.Parent=parent
  return f
 end
 local function line(x,y,x2,y2,width,alpha)
  local dx,dy=x2-x,y2-y
  return shape((x+x2)/2,(y+y2)/2,math.sqrt(dx*dx+dy*dy),width or 3,math.deg(math.atan2(dy,dx)),alpha)
 end
 local function ring(x,y,w,h,width,alpha)
  local f=shape(x,y,w,h,0,1)
  local corner=Instance.new("UICorner",f); corner.CornerRadius=UDim.new(1,0)
  local border=Instance.new("UIStroke",f); border.Color=color; border.Thickness=width or 3; border.Transparency=alpha or 0
  return f
 end
 local function path(points,width,alpha)
  for i=2,#points do line(points[i-1][1],points[i-1][2],points[i][1],points[i][2],width,alpha) end
 end
 local kind=motifs[card.id] or card.symbol
 -- Every illustration is framed by a quiet mini court grid.
 for i=1,3 do line(28,25+i*18,98,25+i*18,1,0.91) end
 line(63,24,63,100,1,0.88)
 if kind=="EYE" then
  path({{25,63},{43,46},{63,40},{83,46},{101,63},{83,80},{63,86},{43,80},{25,63}})
  ring(63,63,24,24); shape(63,63,6,6,45)
 elseif kind=="RESET" then
  local points={}
  for i=0,20 do local a=math.rad(30+i*14); table.insert(points,{63+29*math.cos(a),63+29*math.sin(a)}) end
  path(points); path({{76,31},{88,42},{74,44}})
  line(63,47,63,63); line(63,63,75,70)
 elseif kind=="COURT" then
  path({{34,29},{92,29},{92,97},{34,97},{34,29}},2)
  line(34,63,92,63,4); line(34,47,92,47,2); line(34,79,92,79,2)
  line(63,29,63,47,2); line(63,79,63,97,2)
  shape(63,card.id=="baselineSentinel" and 97 or 79,58,5,0,0)
 elseif kind=="TARGET" or kind=="ORBIT" then
  ring(63,63,62,62,2,0.3); ring(63,63,38,38,2); shape(63,63,8,8,45)
  line(26,63,42,63,2); line(84,63,100,63,2); line(63,26,63,42,2); line(63,84,63,100,2)
 elseif kind=="BOLT" or kind=="WIND" then
  path({{72,28},{43,63},{63,63},{53,99},{85,57},{65,57},{72,28}},4)
  line(28,47,42,47,2,0.5); line(86,80,101,80,2,0.5)
 elseif kind=="DIVE" then
  path({{28,39},{48,35},{66,42},{79,58},{87,79},{87,94}},4)
  path({{77,84},{87,94},{97,84}},4); line(29,96,98,96,2,0.6)
  ring(42,39,12,12,2)
 elseif kind=="SHIELD" then
  path({{63,29},{91,40},{87,74},{77,89},{63,99},{49,89},{39,74},{35,40},{63,29}},3)
  path({{48,63},{59,75},{80,49}},4)
 elseif kind=="MASK" then
  path({{30,40},{63,49},{96,40},{90,78},{74,88},{63,80},{52,88},{36,78},{30,40}},3)
  line(42,58,55,64,4); line(71,64,84,58,4)
 elseif kind=="APEX" then
  path({{27,90},{42,55},{63,31},{84,55},{99,90}},3)
  ring(63,31,17,17,3); line(30,99,96,99,2,0.5)
 elseif kind=="RHYTHM" then
  for i,h in ipairs({16,32,58,76,46,24,12}) do shape(27+i*9,63,4,h,0,i%2==0 and 0 or 0.3) end
 elseif kind=="CLONE" then
  for i=0,2 do
   ring(45+i*17,44+i*3,18,18,2,0.6-i*0.3)
   path({{33+i*17,89},{33+i*17,67},{45+i*17,58},{57+i*17,67},{57+i*17,89}},3,0.6-i*0.3)
  end
 elseif kind=="INFINITY" then
  local points={}
  for i=0,64 do local a=i/64*math.pi*2; table.insert(points,{63+36*math.cos(a),63+23*math.sin(2*a)}) end
  path(points,4); path({{91,34},{99,34},{99,42}},2)
 elseif kind=="PADDLE" then
  local face=ring(61,54,37,48,3); face.Rotation=25
  line(50,77,41,97,9); ring(91,38,13,13,2)
 else
  line(63,35,63,91,5); line(35,63,91,63,5); ring(63,63,64,64,1,0.5)
 end
end
return Art
