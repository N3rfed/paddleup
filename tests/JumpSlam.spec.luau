return function(Rules)
 assert(Rules.JUMP_HANG_TIME==1,"Jump must add one second at the apex")
 for _,side in ipairs({-1,1}) do
  local root=Vector3.new(0,188,side*16)
  assert(Rules.jumpSlam(root,side,false,false),"Airborne kitchen swing is a slam")
  assert(Rules.jumpSlam(Vector3.new(0,188,side*22),side,false,false))
  assert(not Rules.jumpSlam(Vector3.new(0,188,side*(Rules.BASELINE+0.1)),side,false,false))
  assert(not Rules.jumpSlam(root,side,true,false),"Grounded swing is not a jump slam")
  assert(not Rules.jumpSlam(root,side,false,true),"Dives retain their own shots")
  assert(not Rules.jumpSlam(Vector3.new(21,188,side*16),side,false,false))
  assert(Rules.jumpSlam(Vector3.new(0,188,side*Rules.BASELINE),side,false,false),"Baseline jump slams are allowed")
  local frame=CFrame.lookAt(root,root+Vector3.new(0,0,-side))
  assert(Rules.jumpSlamContact(root+Vector3.new(0,3,-side*4),frame))
  assert(not Rules.jumpSlamContact(root+Vector3.new(0,3,-side*40),frame),"Timing cannot grant distant contact")
  assert(not Rules.jumpSlamContact(root+Vector3.new(0,-2,-side*4),frame),"Low balls are normal returns")
  for _,height in ipairs({0,2,5,8}) do
   for _,depth in ipairs({2,5,9}) do
    assert(Rules.jumpLobSlam(root,side,false,false,true,0,root+Vector3.new(0,height,-side*depth),frame),"Reachable airborne lob should be a clean slam")
   end
  end
  local lob=root+Vector3.new(0,3,-side*4)
  assert(not Rules.jumpLobSlam(root,side,true,false,true,0,lob,frame))
  assert(not Rules.jumpLobSlam(root,side,false,true,true,0,lob,frame))
  assert(not Rules.jumpLobSlam(root,side,false,false,false,0,lob,frame))
  assert(not Rules.jumpLobSlam(root,side,false,false,true,1,lob,frame))
  assert(not Rules.jumpLobSlam(root,side,false,false,true,0,root+Vector3.new(0,3,-side*40),frame))
  local contact=root+Vector3.new(0,1.5,-side*5)
  for _,speed in ipairs({30,60,100}) do
   local velocity=Vector3.new(0,-12,side*speed)
   for _,case in ipairs({{0.15,"net"},{0.04,"perfect"},{0,"perfect"},{-0.04,"perfect"},{-0.15,"out"}}) do
    local position=contact-velocity*case[1]
    assert(Rules.slamTiming(position,velocity,contact,false)==case[2],"Signed timing must distinguish approach, contact, and late swings")
   end
   assert(Rules.slamTiming(contact-velocity*0.07,velocity,contact,false)=="net")
   assert(Rules.slamTiming(contact-velocity*0.07,velocity,contact,true)=="perfect","Perfect Vision widens the slam window")
  end
  local target=Vector3.new(3,181.7,-side*35)
  assert(Rules.slamTarget(target,side,"perfect")==target)
  assert(Rules.slamTarget(target,side,"net")==target)
  assert(Rules.slamTarget(target,side,"out").Z*side< -Rules.BASELINE,"Late slam must target beyond baseline")
  assert(Rules.returnFault(0,1,false)~=nil,"Jump slam cannot bypass two-bounce rule")
  assert(Rules.kitchenHitFault(root,false,true),"Jump slam cannot bypass kitchen takeoff rule")
 end
 return "Jump slam eligibility, signed timing, perfect vision, out targeting, and legal-contact regressions passed"
end
