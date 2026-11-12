-- Stable item IDs preserve existing ownership; presentation and new fits live here.
local Catalog={Categories={"Paddles","Wearables","Courts"},Labels={Paddles="Paddles",Wearables="Outfits & Headbands",Courts="Court Customization"},Items={},ById={}}
local function item(id,category,name,price,description,design,colors,fit,hidden)
 local entry={id=id,category=category,name=name,price=price,description=description,asset=design,colors=table.clone(colors),fit=fit,hidden=hidden}
 table.insert(Catalog.Items,entry); Catalog.ById[id]=entry
 return entry
end
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
item("paddle_porcelain","Paddles","Pickle Club",180,"A clean dill pickle illustration on soft pistachio. A clean double-sided print with a dark protective edge.","pickle",{rgb(231,241,215),rgb(36,65,45),rgb(94,152,91)})
item("paddle_tour","Paddles","Catnap Club",260,"An original green-eyed tabby with soft stripes, little paw prints, and a warm cream finish.","cat",{rgb(245,230,203),rgb(118,80,57),rgb(214,155,101)})
item("paddle_afterglow","Paddles","Flame Court",350,"A bold orange-and-gold flame on matte charcoal. Heat-check energy without distracting effects.","flame",{rgb(32,35,44),rgb(23,26,33),rgb(244,154,61)})
item("paddle_confetti","Paddles","Love Rally",320,"A rosy heart, little matching accents, and a warm ivory-pink ground. Love every rally.","heart",{rgb(247,230,229),rgb(125,45,68),rgb(217,93,122)})
item("paddle_prism","Paddles","Checkerboard",300,"Crisp cream-and-ink checks, a restrained club badge, and a clean tournament edge.","checker",{rgb(244,240,230),rgb(36,39,48),rgb(216,208,189)})
item("paddle_lotus","Paddles","Lotus Lake",360,"A pink lotus floating on a quiet jade lake, surrounded by lily pads and gentle ripples. A calm double-sided court finish.","lotus",{rgb(192,219,211),rgb(51,95,84),rgb(235,185,205)})
item("paddle_noir","Paddles","Noir Reserve",700,"Your retained legacy charcoal-and-brass club finish.","luxury",{rgb(36,44,51),rgb(196,165,107),rgb(116,130,132)},nil,true)
local palettes={
 white={rgb(244,241,231),rgb(45,51,61),rgb(120,150,131)},
 black={rgb(37,41,49),rgb(27,30,37),rgb(225,224,216)},
 pink={rgb(233,157,180),rgb(245,229,231),rgb(126,55,79)},
 pickle={rgb(58,112,76),rgb(213,230,182),rgb(241,231,183)},
 flame={rgb(37,41,49),rgb(29,32,40),rgb(243,151,71)},
}
local function outfit(id,name,price,fit,theme)
 local entry=item(id,"Wearables",name.." / "..fit,price,
  (fit=="Female" and "A fitted tennis top and clean court skort" or "A refined court polo and tailored tennis shorts")..
  " with matching headband, court shoes, and restrained piping. "..(theme=="pickle" and "Pickle Club colors." or theme=="flame" and "Flame Court colors." or "A timeless "..theme.." court palette."),
  "outfit",palettes[theme],fit)
 entry.theme=theme
end
outfit("wear_club","Court White",240,"Male","white")
outfit("wear_white_female","Court White",240,"Female","white")
outfit("wear_black_male","Court Black",240,"Male","black")
outfit("wear_black_female","Court Black",240,"Female","black")
outfit("wear_pink_male","Court Pink",280,"Male","pink")
outfit("wear_sunset","Court Pink",280,"Female","pink")
outfit("wear_pickle_male","Pickle Club",320,"Male","pickle")
outfit("wear_pickle_female","Pickle Club",320,"Female","pickle")
outfit("wear_flame_male","Flame Court",350,"Male","flame")
outfit("wear_flame_female","Flame Court",350,"Female","flame")
for _,spec in ipairs({
 {"wear_headband","White Headband","white",160},{"wear_band_black","Black Headband","black",160},
 {"wear_band_pink","Pink Headband","pink",160},{"wear_band_pickle","Pickle Club Headband","pickle",190},
 {"wear_band_flame","Flame Court Headband","flame",190},
}) do
 local entry=item(spec[1],"Wearables",spec[2],spec[4],"A smooth fitted sports headband with contrasting woven piping. Fits either mannequin and your own avatar.","headband",palettes[spec[3]])
 entry.theme=spec[3]
end
-- Retain legacy purchases without cluttering the new gallery.
item("wear_visor","Wearables","Circuit Visor",280,"Your saved midnight sports visor with a cyan brim.","visor",{rgb(34,39,65),rgb(80,223,234),rgb(237,108,181)},nil,true)
item("wear_wrists","Wearables","Rally Wristbands",140,"Your saved contrasting terry cuffs.","wristbands",{rgb(50,159,151),rgb(235,130,107),rgb(245,238,217)},nil,true)
item("wear_towel","Wearables","Courtside Towel",200,"Your saved cream and forest shoulder towel.","towel",{rgb(240,233,209),rgb(38,99,77),rgb(213,174,94)},nil,true)
item("court_classic","Courts","Championship",400,"Professional blue service boxes, green kitchen and quiet cream perimeter. Personal court finish.","classic",{rgb(44,100,139),rgb(62,126,105),rgb(117,138,131)})
item("court_arcade","Courts","Night Circuit",600,"Indigo surface, teal kitchen and neon perimeter rails outside the lines.","neon",{rgb(51,55,99),rgb(47,110,124),rgb(111,83,134)})
item("court_tropical","Courts","Palm Club",500,"Lagoon blue, sage kitchen and warm sand with palm-frond perimeter inlays.","tropical",{rgb(41,117,136),rgb(83,143,120),rgb(184,167,129)})
item("court_noir","Courts","Midnight Reserve",800,"Slate service boxes and a smoky teal kitchen framed by restrained brass inlays.","premium",{rgb(46,57,72),rgb(58,91,94),rgb(80,77,84)})
item("court_colorblock","Courts","Color Club",500,"Sky and lilac service panels, coral kitchen and playful off-court blocks.","multicolor",{rgb(72,125,157),rgb(156,101,112),rgb(133,118,158)})
item("court_modern","Courts","Studio Court",420,"Muted blue-gray and sage, with clean graphite perimeter ticks. Minimal and readable.","modern",{rgb(91,122,136),rgb(108,143,137),rgb(144,146,151)})
for _,entry in ipairs(Catalog.Items) do table.freeze(entry.colors); table.freeze(entry) end
table.freeze(Catalog.Items); table.freeze(Catalog.ById); table.freeze(Catalog.Categories); table.freeze(Catalog.Labels)
return table.freeze(Catalog)
