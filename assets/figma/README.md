# PaddleUp HUD assets

The HUD uses clean background images with live Roblox text and stamina fill.

- Scoreboard source: Scoreboard.png (already stripped of names, scores, and round text; includes its separator).
- Stamina source: Bottom HUD.svg. The generated background retains only the panel outline, cropped to 523 × 87.
- Serving sources: serving-home-2 1.svg and serving-away-1 1.svg. Generated backgrounds omit outlined text; Roblox displays the live server number.

Editable SVGs and Roblox-ready PNG exports are in generated/. Original source files are preserved. When editing those exports, keep live text and stamina fill out of the images. Reupload changed PNGs and update src/client/FigmaAssets.luau.

Current image IDs:
- score: 126088112217729
- stamina: 96729169435447
- servePink: 129909181468346
- serveCyan: 129855733064256
- exit: 98789256384190 (leave.svg → generated/leave.png; original 42 × 42 button)

FigmaHUD.luau draws player names, scores, match format, serving information, stamina, status, and dive cooldown. Other game UI remains controlled by its existing modules.
