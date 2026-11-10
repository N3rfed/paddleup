-- Roblox image IDs for the imported assets/figma PNGs.
-- Temporary Figma download URLs must never be used by the running game.
local Assets = {}
Assets.ids = {
 panelCyan="rbxassetid://104916959855150",panelPurple="rbxassetid://111939750083442",panelPink="rbxassetid://89765864347064",
 menuClassic="rbxassetid://115816136756673",menuArcade="rbxassetid://81675219500663",menuChaos="rbxassetid://113504630861967",
 slotActive="rbxassetid://140378177132265",slotCooldown="rbxassetid://135459973863422",slotReady="rbxassetid://110191213937943",
 howToPlay="rbxassetid://113401742023776",help="rbxassetid://123861671682986",
 vsSplit="rbxassetid://133672889305577",vsClub="rbxassetid://70898401052782",
 vsHomeFrame="rbxassetid://82503268211120",vsAwayFrame="rbxassetid://119027886647125",
 vsHomeNameFrame="rbxassetid://90890564045738",vsAwayNameFrame="rbxassetid://111549661455882",
 vsCountdownFrame="rbxassetid://73057764213215",vsYouFrame="rbxassetid://98288940581989",
 vsRoundFrame="rbxassetid://95784728757085",vsScoring="rbxassetid://96906228612186",vsBadge="rbxassetid://87687598843491",
 -- User-supplied assets/figma/powerups SVGs, converted without changing the originals.
 cleats="rbxassetid://105545555594069", paddle="rbxassetid://116290971602234", pickles="rbxassetid://116652052847050",
 heatseeker="rbxassetid://89077087931839", slipstream="rbxassetid://122155415956278", smallpaddle="rbxassetid://84858966777956",
 glowball="rbxassetid://92434140273047", zerog="rbxassetid://111059136004478",
 deckCard="rbxassetid://126397491413579", deckSelected="rbxassetid://89402832532753", deckEnter="rbxassetid://130446160900351",
 deckBoltLeft="rbxassetid://110044109790537", deckBoltRight="rbxassetid://90612403533433",
 score = "rbxassetid://126088112217729",
 stamina = "rbxassetid://96729169435447",
 -- Keep the original UI for everything outside the scoreboard and stamina.
 homeOuter = "", homeInner = "", awayOuter = "", awayInner = "", round = "",
 servePink = "rbxassetid://129909181468346", serveCyan = "rbxassetid://129855733064256", exit = "rbxassetid://98789256384190",
 card = "", select = "",
}
function Assets.get(name)
 local value = script:GetAttribute(name) or Assets.ids[name]
 if type(value) == "number" and value > 0 then return "rbxassetid://" .. tostring(value) end
 if type(value) == "string" and value:match("^%d+$") then return "rbxassetid://" .. value end
 if type(value) == "string" and value:match("^rbxassetid://%d+$") then return value end
 return nil
end
function Assets.image(parent, name, x, y, width, height)
 local id = Assets.get(name)
 if not id then return nil end
 local image = Instance.new("ImageLabel")
 image.Name = "Figma_" .. name
 image.BackgroundTransparency = 1
 image.Position = UDim2.fromOffset(x, y)
 image.Size = UDim2.fromOffset(width, height)
 image.Image = id
 image.Parent = parent
 return image
end
-- Both templates share the same inner geometry; selected includes 30.5px of glow padding.
function Assets.card(parent,width)
 local base=Assets.image(parent,"deckCard",0,0,width,width*622/569)
 base.Name="CardArt"; base.ScaleType=Enum.ScaleType.Fit
 local selected=Assets.image(parent,"deckSelected",-width*30.5/569,-width*30.5/569,width*630/569,width*683/569)
 selected.Name="SelectedArt"; selected.ScaleType=Enum.ScaleType.Fit; selected.Visible=false
 return base,selected
end
return Assets
