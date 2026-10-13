## Prerequisites
[Invoke-RestMethod](https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1)

[curl](https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh) -sSf

Roblox Studio

[rokit](https://github.com/rojo-rbx/rokit)

Follow these instructions for [rojo](https://rojo.space/docs/v7/getting-started/installation/)

Use the command `npm install -g @openai/codex` to install codex

Visual Studio Code

## Getting Started
1. Clone the repository
2. Using command prompt, change the directory to the destination where the repository was cloned
3. In the repository folder, use the command `rokit install`
4. On the top right of Roblox Studio, there should be an icon for an AI Assistant (looks like a star)
5. Click the 3 dots in the AI Assistant menu
6. Click "Manage MCP Servers"
7. Enable Studio as MCP server"
8. Quick Connect both codex and VS Code
9. Restart VS Code
10. After installing rokit, use the command `rojo serve`
11. On Roblox Studio, there should be a popup to connect to localhost
12. In a different command prompt window, type the command `codex` in the repository destination
13. Sign in with ChatGPT using the credentials provided in the pinned messages
14. Use default configuration when setting up
## Power-up pickups
Pickups descend over 2.4 seconds with a gentle spiral and orbiting gold sparks, then pulse and bob while available. Collection plays a short shrinking burst; the six-second pickup lifetime starts after the descent.
Join Practice, 1V1, or 2V2 to try the placeholder pickups. A glowing 3D orb drops onto each occupied court half after two seconds. Walk into it to collect it and see floating confirmation text. Orbs idle for six seconds before expiring; a collected or expired orb is replaced after eight seconds. Lobby players and spectators cannot collect them. Roster changes clear the pickups.

These are test objects only: they grant no buffs and do not change the existing abilities. `PowerupsCollected` and `LastCollectedPowerup` player attributes record collection for the current server session. `src/server/Powerups.luau` owns spawn timing, positions, distance validation, and cleanup; its `onCollected(player, kind)` callback is the extension point for future inventory/effects. No inventory slot is reserved yet, so test pickups remain repeatable.

## Environment
The rooftop cycles through sunrise, daylight, sunset, and night every 12 real-world minutes. Each server starts at 06:00 and shares the same lighting with all players. Court lights remain on for nighttime play. Adjust CYCLE_SECONDS and START_HOUR in src/server/DayNightCycle.luau to change the duration or starting time.
