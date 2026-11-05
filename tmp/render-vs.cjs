const fs=require('fs'),path=require('path');
const {Resvg}=require('./vs-tools/node_modules/@resvg/resvg-js');
const root='assets/figma/vs_screen',out=path.join(root,'generated');fs.mkdirSync(out,{recursive:true});
const files={vsSplit:'Frame.svg',vsHeading:'Match heading.svg',vsHomeName:'Player 1 nameplate.svg',vsHome:'PLAYER 1.svg',
 vsAwayName:'Player 2 nameplate.svg',vsAway:'PLAYER 2.svg',vsCountdown:'Round start countdown.svg',vsScoring:'Scoring format.svg',vsBadge:'VS.svg'};
let tiles='',index=0;const manifest={};
for(const [key,file] of Object.entries(files)) {
 const png=new Resvg(fs.readFileSync(path.join(root,file)),{fitTo:{mode:'zoom',value:2}}).render().asPng();
 fs.writeFileSync(path.join(out,key+'.png'),png);
 manifest[key]={source:file,png:'generated/'+key+'.png',width:png.readUInt32BE(16),height:png.readUInt32BE(20)};
 const x=index%3*500,y=Math.floor(index/3)*300;
 tiles+=`<image x="${x+10}" y="${y+10}" width="480" height="240" preserveAspectRatio="xMidYMid meet" href="data:image/png;base64,${png.toString('base64')}"/><text x="${x+250}" y="${y+280}" fill="white" font-size="18" font-family="Arial" text-anchor="middle">${file}</text>`;
 index++;
}
fs.writeFileSync(path.join(root,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
fs.writeFileSync('tmp/vs-contact-sheet.png',new Resvg(`<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="900"><rect width="1500" height="900" fill="#10132e"/>${tiles}</svg>`).render().asPng());
console.log(manifest);
