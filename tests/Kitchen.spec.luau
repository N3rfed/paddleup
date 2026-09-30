return function(Rules)
 for _,side in ipairs({-1,1}) do
  local overKitchen=Vector3.new(0,185,side*10)
  local outside=Vector3.new(0,184,side*16)
  for _,diving in ipairs({false,true}) do
   assert(not Rules.kitchenHitFault(outside,overKitchen,side,diving),"Reaching over the kitchen must not cause a foot fault")
   assert(not Rules.kitchenHitFault(Vector3.new(22,184,side*10),overKitchen,side,diving),"Reaching from outside the sideline must be legal")
   for _,depth in ipairs({10,14}) do
    local fault=Rules.kitchenHitFault(Vector3.new(0,184,side*depth),outside,side,diving)
    assert(fault,"Player inside or on the kitchen line must fault on a volley")
    assert(Rules.returnFault(0,2,fault)=="Kitchen volley fault")
    assert(Rules.returnFault(1,2,fault)==nil,"Bounced returns in the kitchen must remain legal")
   end
  end
  assert(Rules.returnFault(0,1,false)=="Two-bounce rule: let the ball bounce")
 end
 return "Kitchen reach, diving, line contact, sidelines, bounced returns, and two-bounce checks passed"
end
