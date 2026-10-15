-- Roblox image IDs for the imported assets/figma PNGs.
-- Temporary Figma download URLs must never be used by the running game.
local Assets = {}
Assets.ids = {
 score = "rbxassetid://126088112217729",
 stamina = "rbxassetid://96729169435447",
 -- Keep the original UI for everything outside the scoreboard and stamina.
 homeOuter = "", homeInner = "", awayOuter = "", awayInner = "", round = "",
 servePink = "rbxassetid://129909181468346", serveCyan = "rbxassetid://129855733064256", help = "", exit = "rbxassetid://98789256384190",
 card = "", select = "", cleats = "", paddle = "", pickles = "",
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
return Assets
