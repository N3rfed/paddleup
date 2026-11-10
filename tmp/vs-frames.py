from pathlib import Path
import xml.etree.ElementTree as E
E.register_namespace('', 'http://www.w3.org/2000/svg')
root=Path('assets/figma/vs_screen'); ns='{http://www.w3.org/2000/svg}'
files={'vsHomeFrame':'PLAYER 1.svg','vsAwayFrame':'PLAYER 2.svg',
 'vsHomeNameFrame':'Player 1 nameplate.svg','vsAwayNameFrame':'Player 2 nameplate.svg',
 'vsCountdownFrame':'Round start countdown.svg','vsYouFrame':'VS.svg'}
for name,source in files.items():
 tree=E.parse(root/source)
 clip=tree.getroot().find(ns+'g').find(ns+'g')
 for child in list(clip):
  if child.tag==ns+'path' and child.get('fill')=='white': clip.remove(child)
 tree.write(root/'generated'/(name+'.svg'),encoding='utf-8',xml_declaration=True)
 if name=='vsHomeFrame':
  for node in tree.getroot().iter():
   for key,value in list(node.attrib.items()):
    if value=='#FF55C8': node.set(key,'#A997FF')
   if node.tag==ns+'feColorMatrix' and node.get('type')=='matrix':
    node.set('values','0 0 0 0 0.663 0 0 0 0 0.592 0 0 0 0 1 0 0 0 0.35 0')
  tree.write(root/'generated'/'vsRoundFrame.svg',encoding='utf-8',xml_declaration=True)
tree=E.parse(root/'Match heading.svg'); svg=tree.getroot()
for child in list(svg)[1:]: svg.remove(child)
tree.write(root/'generated'/'vsClub.svg',encoding='utf-8',xml_declaration=True)
