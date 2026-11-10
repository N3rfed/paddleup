-- Public presentation data. The server reads this same immutable catalog for prices and allowlists.
local Catalog={Categories={"Paddles","Wearables","Courts"},Labels={Paddles="Paddles",Wearables="Clothing & Accessories",Courts="Court Customization"},Items={},ById={}}
local function item(id,category,name,price,description,design,colors)
 local entry={id=id,category=category,name=name,price=price,description=description,asset=design,colors=colors}
 table.insert(Catalog.Items,entry); Catalog.ById[id]=entry
end
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
item("paddle_porcelain","Paddles","Porcelain",180,"Ivory face, graphite spine and a single mint signature. Quiet confidence.","minimal",{rgb(240,237,222),rgb(32,48,56),rgb(74,191,172)})
item("paddle_afterglow","Paddles","Afterglow",350,"Electric cyan rails, magenta circuit steps and an arcade diamond on midnight blue.","arcade",{rgb(27,30,63),rgb(74,229,238),rgb(245,91,182)})
item("paddle_prism","Paddles","Prism Shift",300,"A bold field of alternating coral and navy diamonds with a golden center stripe.","geometric",{rgb(27,57,76),rgb(245,126,104),rgb(245,203,116)})
item("paddle_tour","Paddles","Tour Club",260,"Racing-green face, ivory speed stripes and a numbered championship badge.","sport",{rgb(27,91,70),rgb(242,239,216),rgb(219,181,102)})
item("paddle_confetti","Paddles","Confetti Rally",320,"Coral, sky and lilac tiles celebrate every rally. Same paddle, more personality.","playful",{rgb(246,202,113),rgb(92,183,205),rgb(187,124,204)})
item("paddle_noir","Paddles","Noir Reserve",700,"A dark brushed-metal face with a brass border and inset Art Deco fan.","luxury",{rgb(29,36,43),rgb(207,172,100),rgb(116,130,132)})
item("wear_club","Wearables","Club No. 07",240,"Forest technical jersey panels, ivory chest stripes and the club's number seven.","jersey",{rgb(27,91,70),rgb(241,235,213),rgb(216,181,104)})
item("wear_sunset","Wearables","Sunset League",280,"Coral jersey panels with a stepped lilac sunset and a sky-blue shoulder line.","sunset",{rgb(226,112,101),rgb(178,137,204),rgb(113,209,215)})
item("wear_headband","Wearables","Baseline Headband",160,"An ivory woven headband with mint piping and a little coral center mark.","headband",{rgb(244,236,214),rgb(83,192,171),rgb(232,128,106)})
item("wear_visor","Wearables","Circuit Visor",280,"Midnight sports visor with a cyan brim and pink circuit detailing.","visor",{rgb(34,39,65),rgb(80,223,234),rgb(237,108,181)})
item("wear_wrists","Wearables","Rally Wristbands",140,"A pair of contrasting teal and coral terry cuffs with ivory score stripes.","wristbands",{rgb(50,159,151),rgb(235,130,107),rgb(245,238,217)})
item("wear_towel","Wearables","Courtside Towel",200,"A cream shoulder towel with forest edging and three brass-colored woven stripes.","towel",{rgb(240,233,209),rgb(38,99,77),rgb(213,174,94)})
item("court_classic","Courts","Championship",400,"Professional blue service boxes, green kitchen and quiet cream perimeter. Personal court finish.","classic",{rgb(44,100,139),rgb(62,126,105),rgb(117,138,131)})
item("court_arcade","Courts","Night Circuit",600,"Indigo surface, teal kitchen and neon perimeter rails outside the lines.","neon",{rgb(51,55,99),rgb(47,110,124),rgb(111,83,134)})
item("court_tropical","Courts","Palm Club",500,"Lagoon blue, sage kitchen and warm sand with palm-frond perimeter inlays.","tropical",{rgb(41,117,136),rgb(83,143,120),rgb(184,167,129)})
item("court_noir","Courts","Midnight Reserve",800,"Slate service boxes and a smoky teal kitchen framed by restrained brass inlays.","premium",{rgb(46,57,72),rgb(58,91,94),rgb(80,77,84)})
item("court_colorblock","Courts","Color Club",500,"Sky and lilac service panels, coral kitchen and playful off-court blocks.","multicolor",{rgb(72,125,157),rgb(156,101,112),rgb(133,118,158)})
item("court_modern","Courts","Studio Court",420,"Muted blue-gray and sage, with clean graphite perimeter ticks. Minimal and readable.","modern",{rgb(91,122,136),rgb(108,143,137),rgb(144,146,151)})
for _,entry in ipairs(Catalog.Items) do table.freeze(entry.colors); table.freeze(entry) end
table.freeze(Catalog.Items); table.freeze(Catalog.ById); table.freeze(Catalog.Categories); table.freeze(Catalog.Labels)
return table.freeze(Catalog)
