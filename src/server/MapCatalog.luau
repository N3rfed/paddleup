-- Elevator map presentation and voting choices. Add environment/previews alongside new entries.
local Catalog={}
Catalog.list={
 {id="Rooftop",name="Rooftop",title="SKYLINE CLUB",tagline="City lights. Big rallies.",badge="SKY HIGH",
  accent=Color3.fromRGB(80,232,255),secondary=Color3.fromRGB(255,145,101),
  from=Vector3.new(108,248,124),to=Vector3.new(72,222,91),focus=Vector3.new(0,184,-8)},
 {id="Moon",name="Moon",title="SELENE LUNAR OUTPOST",tagline="Take your rivalry off-world.",badge="OUT OF THIS WORLD",
  accent=Color3.fromRGB(200,156,255),secondary=Color3.fromRGB(255,85,200),
  from=Vector3.new(-130,260,145),to=Vector3.new(-90,230,108),focus=Vector3.new(-5,187,-18)},
}
function Catalog.get(id)
 for _,map in ipairs(Catalog.list) do if map.id==id then return map end end
end
function Catalog.ids()
 local ids={}; for _,map in ipairs(Catalog.list) do table.insert(ids,map.id) end; return ids
end
return Catalog
