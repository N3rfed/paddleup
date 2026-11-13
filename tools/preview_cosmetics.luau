-- Optional Studio command-bar helper for a TEST COPY after Rojo sync. Does not touch player profiles.
-- Paste this file into the Edit command bar. Delete CosmeticShowroom when finished.
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog=require(Shared:WaitForChild("CosmeticCatalog"))
local Assets=require(Shared:WaitForChild("CosmeticAssets"))
local existing=workspace:FindFirstChild("CosmeticShowroom")
if existing then existing:Destroy() end
local root=Instance.new("Model"); root.Name="CosmeticShowroom"
local counts={Paddles=0,Wearables=0,Courts=0}
for _,item in ipairs(Catalog.Items) do
 counts[item.category]+=1
 local index=counts[item.category]
 local asset=Assets.preview(item.id); asset.Name=item.name
 local row=item.category=="Paddles" and 0 or item.category=="Wearables" and 1 or 2
 if row==2 then asset:ScaleTo(0.1) end
 asset:PivotTo(CFrame.new((index-3.5)*7,250+row*9,0)); asset.Parent=root
end
root.Parent=workspace
print("All 18 real cosmetic models are in Workspace.CosmeticShowroom. No profiles were read or written.")
