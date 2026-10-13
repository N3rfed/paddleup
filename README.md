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
Choose Practice, 1V1, 1V2, or 2V2, then choose **Power-Up** or **Augmented**. The shared court accepts players with the same format and ruleset; Spectate skips this choice.

## Augmented matches
Augmented replaces pickups and the Power/Slow abilities with match-long upgrades. After the intro and every three rallies, play pauses for a three-card draft. The server rolls one rarity for everybody (green 60%, yellow 30%, red 10%) and deals different cards to each player, with no overlap within a draft. Yellow upgrades are twice the green strength; red upgrades are three times as strong, with increasingly elaborate animated card art.

Click/tap a card, press 1–3, or select with a controller. Each player picks once; after 20 seconds the server selects the first card for anyone still waiting. Play resumes when everybody has selected. Upgrades stack up to +60% movement, +150% stamina recovery, +40% normal/perfect contact range, and 50% shorter dive cooldown. The HUD shows the current build. A new game or roster change resets builds and starts a fresh draft; spectators receive no offers. Practice drafts apply to the human player; the practice partner retains its normal behavior.

`src/server/Augments.luau` owns rarity, offers, effect definitions and limits. `tests/Augments.spec.luau` covers rarity boundaries, four-player offer uniqueness, invalid selections and stacking limits.

## Power-Up pickup behavior
Pickups descend over 2.4 seconds with a gentle spiral and orbiting gold sparks, then pulse and bob while available. Collection plays a short shrinking burst; the six-second pickup lifetime starts after the descent.
Join Practice, 1V1, or 2V2 to try the placeholder pickups. A glowing 3D orb drops onto each occupied court half after two seconds. Walk into it to collect it and see floating confirmation text. Orbs idle for six seconds before expiring; a collected or expired orb is replaced after eight seconds. Lobby players and spectators cannot collect them. Roster changes clear the pickups.

These are test objects only: they grant no buffs and do not change the existing abilities. `PowerupsCollected` and `LastCollectedPowerup` player attributes record collection for the current server session. `src/server/Powerups.luau` owns spawn timing, positions, distance validation, and cleanup; its `onCollected(player, kind)` callback is the extension point for future inventory/effects. No inventory slot is reserved yet, so test pickups remain repeatable.

## Environment
The rooftop cycles through sunrise, daylight, sunset, and night every 12 real-world minutes. Each server starts at 06:00 and shares the same lighting with all players. Court lights remain on for nighttime play. Adjust CYCLE_SECONDS and START_HOUR in src/server/DayNightCycle.luau to change the duration or starting time.
