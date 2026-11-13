"""Generate clean, antialiased print artwork for Paddle Up paddle decals."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math, random
OUT=Path(__file__).resolve().parents[1]/"assets"/"shop"
OUT.mkdir(parents=True,exist_ok=True)
W,H,S=1024,1280,3
def font(size):
 for name in ["C:/Windows/Fonts/arialbd.ttf","C:/Windows/Fonts/segoeuib.ttf"]:
  if Path(name).exists(): return ImageFont.truetype(name,int(size*S))
 return ImageFont.load_default()
def canvas(bg):
 im=Image.new("RGB",(W*S,H*S),bg)
 return im,ImageDraw.Draw(im)
def box(draw,xy,fill,r=0,outline=None,width=1):
 xy=tuple(int(v*S) for v in xy)
 if r: draw.rounded_rectangle(xy,radius=r*S,fill=fill,outline=outline,width=width*S)
 else: draw.rectangle(xy,fill=fill,outline=outline,width=width*S)
def ellipse(d,xy,fill,outline=None,width=1): d.ellipse(tuple(int(v*S) for v in xy),fill=fill,outline=outline,width=width*S)
def line(d,points,color,width=4): d.line([(int(x*S),int(y*S)) for x,y in points],fill=color,width=width*S,joint="curve")
def poly(d,points,color): d.polygon([(int(x*S),int(y*S)) for x,y in points],fill=color)
def text(d,xy,value,size,color):
 d.text((int(xy[0]*S),int(xy[1]*S)),value,font=font(size),fill=color,anchor="mm",stroke_width=0)
def brand(d,color,subtitle):
 text(d,(512,120),"P A D D L E  U P",32,color)
 text(d,(512,1160),subtitle,30,color)
def border(d,color): box(d,(42,42,W-43,H-43),None,90,color,5)
def save(im,name): im.resize((W,H),Image.Resampling.LANCZOS).save(OUT/(name+".png"))
def heart(cx,cy,size):
 return [(cx+size*16*math.sin(t)**3/17,cy-size*(13*math.cos(t)-5*math.cos(2*t)-2*math.cos(3*t)-math.cos(4*t))/17)
  for t in [2*math.pi*i/240 for i in range(240)]]
im,d=canvas("#E7F1D7");border(d,"#356D43");brand(d,"#28553A","DILL WITH IT")
ellipse(d,(135,300,889,1054),"#D3E6B4")
pickle=Image.new("RGBA",(W*S,H*S));p=ImageDraw.Draw(pickle)
box(p,(330,300,700,1030),"#39834B",160,"#215A36",10)
box(p,(360,335,407,945),"#68AB65",22)
rng=random.Random(41)
for i in range(34):
 x=rng.randint(430,655);y=rng.randint(355,970);r=rng.randint(7,15)
 ellipse(p,(x-r,y-r,x+r,y+r),"#276C3D")
pickle=pickle.rotate(-13,resample=Image.Resampling.BICUBIC,center=(512*S,650*S))
im=Image.alpha_composite(im.convert("RGBA"),pickle);save(im,"pickle")
im,d=canvas("#F5E6CB");border(d,"#86684B");brand(d,"#654C37","CATNAP CLUB")
ellipse(d,(125,290,899,1064),"#EAD7B8")
# Original warm tabby mascot: green eyes, striped forehead, cream muzzle; no bow.
poly(d,[(241,523),(230,274),(425,430)],"#765039")
poly(d,[(269,477),(261,332),(391,440)],"#E9AF9D")
poly(d,[(603,430),(796,274),(783,523)],"#765039")
poly(d,[(635,440),(765,332),(756,477)],"#E9AF9D")
ellipse(d,(223,383,801,971),"#D69B65","#765039",9)
for points in [[(420,403),(462,520),(479,394)],[(491,390),(515,545),(542,391)],[(554,394),(571,520),(610,404)]]:
 poly(d,points,"#A87149")
for side in [-1,1]:
 cx=512+side*122
 ellipse(d,(cx-49,581,cx+49,662),"#E7E1B2","#765039",5)
 ellipse(d,(cx-26,588,cx+26,655),"#789C6D")
 ellipse(d,(cx-9,592,cx+9,651),"#3D392E")
 ellipse(d,(cx-13,597,cx-3,609),"#FFFCED")
ellipse(d,(367,692,518,837),"#FAF0DC")
ellipse(d,(506,692,657,837),"#FAF0DC")
poly(d,[(479,710),(545,710),(512,748)],"#B66E6B")
line(d,[(512,747),(512,776)],"#765039",6)
d.arc((461*S,747*S,513*S,794*S),0,160,fill="#765039",width=5*S)
d.arc((511*S,747*S,563*S,794*S),20,180,fill="#765039",width=5*S)
for side in [-1,1]:
 for y,dy in [(726,-12),(780,12)]:
  line(d,[(512+side*174,y),(512+side*299,y+dy)],"#765039",5)
for cx,cy in [(163,1032),(864,312)]:
 ellipse(d,(cx-20,cy-3,cx+20,cy+28),"#BEA17D")
 for dx,dy in [(-28,-23),(-9,-35),(13,-34),(30,-18)]:
  ellipse(d,(cx+dx-8,cy+dy-10,cx+dx+8,cy+dy+10),"#BEA17D")
save(im,"cat")
im,d=canvas("#20232C");border(d,"#F08C4B");brand(d,"#F9CE91","HEAT CHECK")
outer=[(510,1030),(290,980),(216,811),(252,663),(358,526),(356,715),(481,535),(555,276),(664,467),(646,619),(761,499),(820,714),(778,920),(644,1021)]
poly(d,outer,"#E65635")
inner=[(512,990),(337,941),(289,802),(360,662),(399,804),(544,578),(585,433),(611,656),(729,649),(751,799),(685,948)]
poly(d,inner,"#F49A3D")
core=[(512,963),(423,910),(411,817),(526,687),(535,809),(626,726),(670,848),(607,944)]
poly(d,core,"#FFE3A0")
for x,y,r in [(240,414,10),(765,313,8),(840,951,8),(192,995,6),(736,1080,6)]:
 ellipse(d,(x-r,y-r,x+r,y+r),"#F6AE58")
save(im,"flame")
im,d=canvas("#F7E6E5");border(d,"#BC536E");brand(d,"#A53C58","LOVE THE RALLY")
poly(d,heart(512,660,356),"#F4B6C4")
poly(d,heart(512,660,321),"#D95D7A")
poly(d,heart(490,643,285),"#EB7893")
for x,y,r in [(175,302,49),(836,1004,48),(824,328,32),(188,1013,29)]:
 poly(d,heart(x,y,r),"#BC536E")
line(d,[(348,552),(371,525),(412,514)],"#FFEAE7",13)
save(im,"heart")
im,d=canvas("#F4F0E6")
step=128
for row in range(10):
 for col in range(8):
  box(d,(col*step,row*step,(col+1)*step,(row+1)*step),"#242730" if (row+col)%2 else "#F4F0E6")
box(d,(38,38,986,1242),None,65,"#D8D0BD",10)
box(d,(250,85,774,198),"#F4F0E6",26,"#242730",4)
text(d,(512,140),"PADDLE UP / CLUB",30,"#242730")
box(d,(270,1054,754,1150),"#242730",22)
text(d,(512,1103),"CHECKMATE",30,"#F4F0E6")
save(im,"checkerboard")
im,d=canvas("#242C33");border(d,"#C4A56B");brand(d,"#C4A56B","NOIR RESERVE")
for i in range(-3,4):
 line(d,[(512+i*67,960),(512+i*110,350)],"#C4A56B",4)
save(im,"noir")
# Quiet lake scene with lily pads and a layered pink lotus.
im,d=canvas("#C0DBD3")
for y in range(H):
 t=y/H
 color=tuple(round(a+(b-a)*t) for a,b in zip((198,222,213),(116,167,157)))
 box(d,(0,y,W,y+1),color)
border(d,"#47796E");brand(d,"#335F54","LOTUS LAKE")
def water(cx,cy,rx,ry,color,width=3):
 d.arc(((cx-rx)*S,(cy-ry)*S,(cx+rx)*S,(cy+ry)*S),8,170,fill=color,width=width*S)
 d.arc(((cx-rx)*S,(cy-ry)*S,(cx+rx)*S,(cy+ry)*S),200,345,fill=color,width=width*S)
for x,y,rx,ry in [(512,878,362,80),(512,878,404,106),(193,1004,158,52),(810,399,115,35),(277,333,126,39)]:
 water(x,y,rx,ry,"#DFEBDF",3)
def pad(cx,cy,rx,ry):
 ellipse(d,(cx-rx,cy-ry,cx+rx,cy+ry),"#51856A","#3C6B54",4)
 poly(d,[(cx,cy),(cx+rx*0.7,cy-ry*0.85),(cx+rx*0.97,cy-ry*0.3)],"#9DC5B5")
 line(d,[(cx-rx*0.65,cy+ry*0.2),(cx,cy),(cx+rx*0.8,cy+ry*0.3)],"#7BA183",3)
pad(248,327,109,43);pad(824,401,102,40);pad(193,1004,142,55);pad(818,1044,137,51)
pad(512,844,299,97)
def cubic(a,b,c,e,n=36):
 points=[]
 for i in range(n+1):
  t=i/n;u=1-t
  points.append((u*u*u*a[0]+3*u*u*t*b[0]+3*u*t*t*c[0]+t*t*t*e[0],u*u*u*a[1]+3*u*u*t*b[1]+3*u*t*t*c[1]+t*t*t*e[1]))
 return points
def petal(base,tip,left,right,color):
 points=cubic(base,left,(tip[0]-22,tip[1]+58),tip)
 points+=cubic(tip,(tip[0]+22,tip[1]+58),right,base)
 poly(d,points,color);line(d,points+[points[0]],"#AD6E87",3)
base=(512,795)
petal(base,(309,391),(290,713),(456,408),"#EBC2CF")
petal(base,(715,391),(567,408),(737,713),"#EBC2CF")
petal(base,(512,321),(377,609),(647,609),"#F2D4DC")
petal(base,(192,590),(214,821),(444,571),"#DBA1B7")
petal(base,(832,590),(580,571),(810,821),"#DBA1B7")
petal(base,(351,509),(292,751),(474,549),"#EFBECE")
petal(base,(673,509),(550,549),(732,751),"#EFBECE")
petal(base,(512,460),(407,687),(617,687),"#F8DDE4")
petal((512,813),(282,708),(324,872),(439,686),"#D990AD")
petal((512,813),(742,708),(585,686),(700,872),"#D990AD")
for x,y in [(487,760),(512,752),(537,760)]:
 ellipse(d,(x-7,y-12,x+7,y+8),"#E4BE72")
save(im,"lotus_lake")
thumbs=[]
for name in ["pickle","cat","flame","heart","checkerboard","lotus_lake"]:
 pic=Image.open(OUT/(name+".png")).convert("RGB");pic.thumbnail((256,320));thumbs.append(pic)
sheet=Image.new("RGB",(6*276,360),"#EEEAE3")
for i,pic in enumerate(thumbs):sheet.paste(pic,(i*276+10,15))
sheet.save(OUT/"contact-sheet.jpg",quality=95)
print("Generated seven paddle prints and contact sheet in",OUT)
