-- Flat, resolution-independent illustrations using the HUD palette.
local Art={}
function Art.mount(parent,kind,accent)
 local root=Instance.new("Frame")
 root.Name="Artwork"; root.BackgroundTransparency=1; root.Size=UDim2.fromScale(1,1); root.Parent=parent
 local white=Color3.fromRGB(246,246,255)
 local pink=Color3.fromRGB(255,85,200)
 local cyan=Color3.fromRGB(80,232,255)
 local navy=Color3.fromRGB(27,27,64)
 local function shape(parent,name,x,y,w,h,color,radius,angle)
  local f=Instance.new("Frame"); f.Name=name; f.AnchorPoint=Vector2.new(0.5,0.5)
  f.Position=UDim2.fromScale(x,y); f.Size=UDim2.fromScale(w,h)
  f.BackgroundColor3=color; f.BorderSizePixel=0; f.Rotation=angle or 0; f.ZIndex=2; f.Parent=parent
  if radius then local c=Instance.new("UICorner",f); c.CornerRadius=UDim.new(radius,0) end
  return f
 end
 local halo=shape(root,"Halo",0.52,0.48,0.65,0.8,accent,1)
 halo.BackgroundTransparency=0.92
 local function paddle(x,y,angle,color)
  local p=shape(root,"Paddle",x,y,0.27,0.62,navy,nil,angle); p.BackgroundTransparency=1
  shape(p,"Handle",0.5,0.84,0.23,0.36,white,0.25)
  shape(p,"Face",0.5,0.34,0.96,0.69,color,0.4)
  local stripe=shape(p,"FaceStripe",0.5,0.42,0.58,0.06,white,0.5,-30)
  stripe.BackgroundTransparency=0.35
 end
 local function ball(x,y)
  local b=shape(root,"Ball",x,y,0.15,0.2,white,1)
  for _,xy in ipairs({{0.33,0.32},{0.68,0.36},{0.5,0.69}}) do
   shape(b,"Hole",xy[1],xy[2],0.13,0.13,navy,1)
  end
 end
 if kind=="Moon" or kind=="Rooftop" then
  local court=shape(root,"Court",0.48,0.57,0.69,0.57,accent,0.08,-9)
  court.BackgroundTransparency=0.8
  local edge=Instance.new("UIStroke",court); edge.Color=accent; edge.Thickness=1.5
  for _,line in ipairs({{0.5,0.5,1,0.025},{0.5,0.5,0.015,1},{0.5,0.25,1,0.015},{0.5,0.75,1,0.015}}) do
   shape(court,"Line",line[1],line[2],line[3],line[4],white)
  end
  if kind=="Moon" then
   local moon=shape(root,"Moon",0.79,0.22,0.22,0.28,white,1)
   shape(moon,"Crater",0.38,0.4,0.22,0.22,Color3.fromRGB(181,187,225),1)
  else
   for i=1,3 do shape(root,"Tower",0.18+i*0.14,0.2,0.1,0.12+i*0.045,accent,0.08) end
  end
 elseif kind=="1V1" or kind=="1V2" or kind=="2V2" then
  local count=kind=="2V2" and 4 or kind=="1V2" and 3 or 2
  for i=1,count do
   local x=0.5+(i-(count+1)/2)*0.19
   shape(root,"PlayerHead",x,0.36,0.1,0.15,i<=math.floor(count/2) and cyan or pink,1)
   shape(root,"PlayerBody",x,0.57,0.14,0.22,i<=math.floor(count/2) and cyan or pink,0.4)
  end
 else
  paddle(kind=="Arcade" and 0.4 or 0.46,0.5,-24,accent)
  if kind=="Arcade" then paddle(0.65,0.51,23,pink) end
  ball(0.77,0.29)
  if kind=="Chaos" then
   for _,xy in ipairs({{0.22,0.25},{0.76,0.72},{0.85,0.5}}) do
    shape(root,"Spark",xy[1],xy[2],0.05,0.08,pink,0.1,45)
   end
  end
 end
 return root
end
return Art
