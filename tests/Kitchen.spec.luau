return function(Rules)
 local moving=Vector3.new(10,0,0)
 local function update(state,position,grounded,velocity,dt)
  return Rules.updateKitchen(state,position,grounded,velocity or moving,dt or 1/60)
 end
 for _,side in ipairs({-1,1}) do
  local inside=Vector3.new(0,184,side*10)
  local line=Vector3.new(0,184,side*14)
  local outside=Vector3.new(0,184,side*14.5)
  for _,position in ipairs({outside,Vector3.new(20.5,184,side*10)}) do
   local state={volleyPending=true}
   assert(not update(state,position,true),"Dive landing outside the painted kitchen must not fault")
   assert(not state.kitchenTouched,"Outside takeoff must not be tagged as kitchen contact")
   assert(not Rules.kitchenHitFault(position,true,state.kitchenTouched),"Grounded reach from outside is legal")
   assert(not update(state,inside,false),"Flying over the kitchen must not count as landing")
   assert(not Rules.kitchenHitFault(inside,false,state.kitchenTouched),"Airborne dive from outside is legal")
   assert(state.volleyPending,"Airborne volley must still be checked on landing")
   assert(not update(state,position,true),"Landing outside after an airborne volley is legal")
  end
  for _,position in ipairs({inside,line,Vector3.new(20,184,side*10)}) do
   local state={volleyPending=true}
   assert(update(state,position,true),"Volley momentum into kitchen or onto its lines must fault")
   assert(state.kitchenTouched)
   assert(Rules.kitchenHitFault(position,true,false),"Ground contact in the kitchen must fault at impact")
   assert(Rules.kitchenHitFault(outside,false,state.kitchenTouched),"Jumping out of the kitchen does not restore volley eligibility")
   assert(not update(state,outside,true),"Ground contact outside resets takeoff eligibility")
   assert(not Rules.kitchenHitFault(inside,false,state.kitchenTouched))
  end
  local state={volleyPending=true}
  assert(not update(state,outside,true,Vector3.zero,0.1))
  assert(state.volleyPending,"Brief pause must not clear volley momentum")
  assert(not update(state,outside,true,Vector3.zero,0.1))
  assert(not state.volleyPending,"Settling outside ends the landing check")
  assert(not update(state,inside,true),"Entering kitchen after settling is legal")
  state={volleyPending=true}
  assert(update(state,line,true,Vector3.zero,0.2),"Illegal landing must fault even on a long settling frame")
  local fault=Rules.kitchenHitFault(inside,true,false)
  assert(Rules.returnFault(0,2,fault)=="Kitchen volley fault")
  assert(Rules.returnFault(1,2,fault)==nil,"Bounced returns inside the kitchen remain legal")
  assert(not update({},inside,true),"Kitchen contact without a volley is legal")
  assert(Rules.returnFault(0,1,false)=="Two-bounce rule: let the ball bounce")
 end
 return "Kitchen boundaries, airborne dives, takeoff, landing, momentum, bounced returns, and two-bounce checks passed"
end
