return function(Assets,Catalog)
 local counts={Paddles=0,Wearables=0,Courts=0}
 local roots={}
 local ok,err=pcall(function()
  for _,item in ipairs(Catalog.Items) do
   counts[item.category]+=1
   local root=Assets.preview(item.id); table.insert(roots,root)
   assert(#root:GetDescendants()>5,"Every item builds actual geometry")
   for _,p in ipairs(root:GetDescendants()) do if p:IsA("BasePart") then
    assert(not p.CanCollide and not p.CanQuery and not p.CanTouch and p.Massless,"Art must never affect physics")
   end end
   if item.category=="Paddles" then
    local face=root.PaddleFace; local originalSize=face.Size; local cf=face.CFrame
    assert(face:FindFirstChild("ShopPaddleArt") and #face.ShopPaddleArt:GetChildren()>=4)
    Assets.paddle(face,nil)
    assert(face.Size==originalSize and face.CFrame==cf and face.Color==Color3.fromRGB(31,193,180) and not face:FindFirstChild("ShopPaddleArt"),"Paddle unequip restores its original face without resizing")
   elseif item.category=="Wearables" then
    assert(root:FindFirstChild("ShopWearable") and #root.ShopWearable:GetChildren()>0)
    local shirt=Instance.new("Shirt"); shirt.ShirtTemplate="rbxassetid://123"; shirt.Parent=root
    Assets.wear(root,nil); assert(shirt.Parent==root and not root:FindFirstChild("ShopWearable"),"Unequipping preserves default clothing")
   else
    assert(root:FindFirstChild("ShopCourtArt") and #root.ShopCourtArt:GetChildren()>0)
    local surface=root["Playing surface"]; local size=surface.Size; local cf=surface.CFrame
    local line=root.Sideline; local lineColor=line.Color
    Assets.court(root,nil)
    assert(surface.Size==size and surface.CFrame==cf and line.Color==lineColor,"Court cosmetics preserve dimensions and markings")
    assert(surface.Color==Color3.fromRGB(43,123,134))
    surface:SetAttribute("ShopCourtBaseColor",Color3.fromRGB(48,89,107))
    Assets.court(root,item.id); Assets.court(root,nil)
    assert(surface.Color==Color3.fromRGB(48,89,107),"Default restoration respects the active Moon environment")
   end
  end
  assert(counts.Paddles>=6 and counts.Wearables>=6 and counts.Courts>=6)
  local a=Assets.preview("court_classic"); local b=Assets.preview("court_tropical"); table.insert(roots,a); table.insert(roots,b)
  local color=b["Playing surface"].Color
  Assets.court(a,"court_noir")
  assert(b["Playing surface"].Color==color,"One court's finish cannot alter another")
  -- R6 limb names and scaled body dimensions are supported by the same wearable builders.
  local rig=Instance.new("Model"); table.insert(roots,rig)
  for _,spec in ipairs({{"Head",Vector3.new(2,1,1)},{"Torso",Vector3.new(2,2,1)},{"Left Arm",Vector3.new(1,2,1)},{"Right Arm",Vector3.new(1,2,1)}}) do
   local p=Instance.new("Part"); p.Name=spec[1]; p.Size=spec[2]; p.Parent=rig
  end
  for _,item in ipairs(Catalog.Items) do if item.category=="Wearables" then Assets.wear(rig,item.id); assert(#rig.ShopWearable:GetChildren()>0) end end
 end)
 for _,root in ipairs(roots) do root:Destroy() end
 assert(ok,err)
 return "All 18 real designs built, nonphysical art, R6/R15 wearables, unchanged paddle/court geometry, default restoration and isolated themes passed"
end
