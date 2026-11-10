-- Mutates only a transaction-local copy. Called inside the existing profile UpdateAsync transform.
local Catalog=require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("CosmeticCatalog"))
local Rules={}
local MAX=9007199254740991
function Rules.isOperation(kind) return kind=="ShopBuy" or kind=="ShopEquip" or kind=="ShopUnequip" end
function Rules.validate(data)
 assert(type(data.spendableXP)=="number" and data.spendableXP%1==0 and data.spendableXP>=0 and data.spendableXP<=MAX,"Invalid shop balance")
 assert(type(data.inventory)=="table" and type(data.equipped)=="table","Invalid inventory")
 for id,owned in pairs(data.inventory) do assert(type(id)=="string" and #id<=80 and owned==true,"Invalid owned cosmetic") end
 for category,id in pairs(data.equipped) do
  assert(Catalog.Labels[category] and type(id)=="string" and data.inventory[id]==true,"Invalid equipped cosmetic")
  assert(Catalog.ById[id] and Catalog.ById[id].category==category,"Invalid equipment category")
 end
end
function Rules.apply(data,operation)
 if operation.kind=="ShopUnequip" then
  if not Catalog.Labels[operation.category] then return "InvalidItem" end
  data.equipped[operation.category]=nil; return "Unequipped"
 end
 local item=type(operation.item)=="string" and Catalog.ById[operation.item]
 if not item then return "InvalidItem" end
 if operation.kind=="ShopBuy" then
  if data.inventory[item.id] then return "Owned" end
  if data.spendableXP<item.price then return "Insufficient" end
  data.spendableXP-=item.price; data.inventory[item.id]=true
  return "Purchased"
 elseif operation.kind=="ShopEquip" then
  if not data.inventory[item.id] then return "NotOwned" end
  data.equipped[item.category]=item.id; return "Equipped"
 end
 error("Unknown shop operation")
end
return Rules
