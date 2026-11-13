# PaddleUp Goods

Press **E** (controller **X**, or tap the prompt) at the existing **PaddleUp Goods boutique counter** in the lobby. Six physical paddle samples identify the counter. Browse Paddles, Clothing & Accessories, and Court Customization. Each card and the rotating fitting room build the actual cosmetic model, not a stock thumbnail. Select an item to see its description, price and status. Buying opens a cost/balance confirmation; owning an item enables Equip/Unequip. Use Original restores the category default. Retry resumes the existing queued transaction after a storage error. Close, Escape, controller B, respawning or entering a match closes the shop. The interface supports mouse, touch and controller navigation, stacked phone layouts and scaled short viewports.

## Actual assets

All designs are native Roblox Parts, WeldConstraints, colors and materials, defined in `src/server/Cosmetics/CosmeticAssets.luau` and referenced by `CosmeticCatalog.luau`. There are no remote image dependencies, placeholder asset IDs, MeshPart permissions or upload requirements. Both paddle faces carry their design. Numbering is geometry so it also renders inside ViewportFrames. Wearables use torso/head/hand/arm geometry sized from the character's actual body parts, supporting R6 and R15. Existing shirts, accessories and body parts are retained.

| Category | Item | Spendable XP | Implemented design |
| --- | --- | ---: | --- |
| Paddles | Porcelain | 180 | Ivory, graphite spine and mint signature |
| Paddles | Afterglow | 350 | Midnight blue, cyan neon rails, pink circuits and diamond |
| Paddles | Prism Shift | 300 | Coral diamond grid on navy with golden axis |
| Paddles | Tour Club | 260 | Racing green, ivory speed stripes and geometric 07 badge |
| Paddles | Confetti Rally | 320 | Yellow face with angled sky/lilac confetti tiles |
| Paddles | Noir Reserve | 700 | Metal face, brass frame and Art Deco fan |
| Clothing & Accessories | Club No. 07 | 240 | Forest jersey panels, ivory stripes, gold geometric number |
| Clothing & Accessories | Sunset League | 280 | Coral jersey, lilac stripes/stepped sunset, sky piping |
| Clothing & Accessories | Baseline Headband | 160 | Ivory woven headband, mint piping, coral mark |
| Clothing & Accessories | Circuit Visor | 280 | Midnight headband, cyan brim and pink mark |
| Clothing & Accessories | Rally Wristbands | 140 | Contrasting teal/coral cuffs and cream score stripes |
| Clothing & Accessories | Courtside Towel | 200 | Cream shoulder towel, forest hems, woven gold stripes |
| Court Customization | Championship | 400 | Blue/green professional finish and cream perimeter bands |
| Court Customization | Night Circuit | 600 | Indigo/teal finish, cyan rails and pink off-court nodes |
| Court Customization | Palm Club | 500 | Lagoon/sage/sand finish with palm-frond inlays |
| Court Customization | Midnight Reserve | 800 | Slate/teal finish with brass perimeter diamonds |
| Court Customization | Color Club | 500 | Sky/lilac service boxes, coral kitchen and multicolor perimeter tiles |
| Court Customization | Studio Court | 420 | Muted blue-gray/sage finish and graphite perimeter ticks |

There is one persistent slot per category. Switching a wearable replaces the previous shop wearable; the player's underlying avatar remains intact. Original paddle, avatar and court finishes are always available without purchase.

`tools/preview_cosmetics.luau` materializes all 18 models in a test copy of Studio after a full Rojo sync. It never accesses profiles. Delete its `Workspace.CosmeticShowroom` model when finished. Runtime boutique displays use the same asset builder.

## Currency and transaction model

`totalXP` is lifetime earned XP and never decreases. Existing `level` and `xp` remain level/current-level progress, with the existing BaseXP/LinearXP/QuadraticXP formula unchanged. `spendableXP` is a separate nonnegative shop balance. `ProgressionConfig.ShopCurrencyRatio` centralizes earning (initially **1:1**). Each actual XP grant mints `floor(grantedXP * ratio)` currency. This includes daily grants, seventh-day bonuses, capped gameplay awards and the existing +5% multiplier. Rejected, capped-out and duplicate grants mint nothing.

Purchases subtract only `spendableXP`. The catalog on the server controls item IDs, prices and categories. Clients send only an action, request sequence, interaction token and item/category ID. Ownership, funds and equipment are validated inside the existing `UpdateAsync` transform against the latest record. Ownership and the debit commit together in the same `PaddleUpProgression_v1` record/key. There is no second wallet store or cached `SetAsync` save.

The original receipt/idempotency mechanism covers shop operations too. Retrying an unknown result uses the same queued operation ID; a second purchase ID still encounters permanent ownership and cannot charge again. Equipment changes cost nothing. One shop operation per player can be queued at once. Prompt and every mutation require a living lobby character within 12 studs; tokens expire after three minutes. Requests are rate-limited and sequence-checked. A closed or stale token cannot authorize purchases. Failed saves keep the operation for existing Retry/backoff/shutdown handling; UI ownership and equipment follow only confirmed records.

`ProgressionService` publishes confirmed profile changes to the shop and cosmetic renderer. Both the club profile and shop distinguish level progress, lifetime earned XP and spendable XP. Cosmetic errors cannot change scoring or abort a profile commit.

## Safe migration and rollout

Schema **3** uses the existing store name and `player_<UserId>` keys. The first successful load of a version-1 or version-2 record initializes `spendableXP = floor(existing totalXP * ShopCurrencyRatio)` and empty shop inventory/equipment. It preserves level, current XP, lifetime XP, history, streaks, weekly awards, receipts, budgets, active/pending time zones and deadlines. The existing v1 time-zone migration still runs. Version 3 is the one-time migration marker: repeated loads, transform retries and reconnects never reissue the opening balance. New players start with zero currency. Invalid or newer-schema data fails closed rather than being replaced.

Publish/sync **all changed modules and `default.project.json` together**, then restart older servers. Older progression code rejects schema 3; it cannot safely use new records. No production player records were seeded, reset or migrated during development. Do not enable Studio API access against production just to test this feature. Use a separate published test experience for real persistence acceptance.

## Gameplay and visual isolation

PaddleFace dimensions (1.65 x 2 x 0.3), grip dimensions/position, existing welds, hit detection, physics, movement and gameplay rules are unchanged. Added art is massless, noncolliding, untouchable and excluded from queries. Wearable removal deletes only its own ShopWearable model. Character respawns and newly created gameplay paddles receive the confirmed selection.

Court finishes run exclusively in the local player's client, on their active court. Opponents may see different finishes in the same match. Surface colors/materials and nonphysical inlays change; boundaries, net, lights, ball and dimensions stay intact. Service-panel color overlays sit below the existing lines. Switching courts, leaving a match or unequipping restores the default. Server-provided original color/material attributes preserve the active Rooftop/Moon default. Spectators keep the original finish.

## Verification

Automated Studio tests use detached instances, controlled clocks, fake remotes and fake DataStores. Tests cover all 18 real assets, R6/R15 construction, buy/preview/equip/unequip, independent players, respawn/recreated paddles, client-specific court rendering, insufficient funds, duplicate IDs and repeat purchases, authoritative prices, proximity/token/rate limits, three categories, confirmation, phone/landscape layouts, stale UI packets, failed saves, unknown commit results, two simulated servers, rejoining, repeat-safe migration and preserved lifetime XP/levels. Existing daily/weekly/multiplier/time-zone, queue, scoring and powerup regressions are also exercised. Real generated paddle, wearable and court models were visually inspected in Studio; temporary review objects were removed.

New fixtures: `ShopTransactions`, `CosmeticAssets`, `ShopService`, `ShopUI`, `CosmeticApplication`. Run them with the existing Studio fixture pattern described in PROGRESSION.md. Pass the corresponding real module tables and/or module Source strings; fixtures specify their arguments. They do not require production API access. ProgressionService.spec also exercises shop queue deduplication, confirmed currency attributes and equipment persistence.

Remaining acceptance before publishing: physically walk to the boutique and use E/X/touch in a running session; exercise controller focus and actual device layouts; inspect equipped visuals on varied avatar bundles and bulky UGC/hair; complete a qualified multiplayer/practice match; buy and equip, then rejoin a separate published test experience/server and verify the saved balance, inventory, level and selected time zone. Observe two real clients choosing different court themes. Arbitrary avatar meshes/accessories may need additional fit tuning; the shop uses additive geometry rather than layered clothing. Backend outages and cross-server behavior have been simulated, not proven against Roblox's live storage service. This feature has not been published.

## Files and systems

New shared: `CosmeticCatalog`, `CosmeticAssets`. New server: `ShopRules`, `ShopService`, `CosmeticService`. New client: `ShopUI`, `CourtCosmetics`. Existing integration: `ProgressionConfig`, `ProgressionRules`, `ProgressionService`, `CourtEnvironments` (default-finish metadata only), server/client bootstraps, `ProgressionUI`, `LobbyCamera`, and `default.project.json`. Existing fixture updates: TimeZones' schema expectation, CheckInUTC's subscriber mock, ProgressionService's shop coverage. Gameplay simulation and reward qualification remain unchanged.


### Verification record (2026-11-10)

Passed: all **121** Luau source/test chunks compiled; **18** fixtures passed; Rojo build and `git diff --check` passed. The 18 fixtures were ShopTransactions, CosmeticAssets, ShopService, ShopUI, CosmeticApplication, ProgressionService, ProgressionUI, TimeZones, ProgressionRules, ProgressionRepository, MatchRewards, CheckInUTC, SharedModuleStartup, MatchQueueAdmission, JumpSlamServer, CourtSession, PowerupServer and CourtEnvironments. No live DataStores were used. Source/gameplay fixtures and visual review objects remained detached or temporary; review objects were removed.

To reproduce the five new tests in a synced test copy, import their fixture files as ModuleScripts under a temporary `ServerStorage.ShopTests` folder (names without `.luau`), then run in an executor with loadstring support:

```lua
local S = game.ServerScriptService.Server
local C = game.StarterPlayer.StarterPlayerScripts.Client
local Shared = game.ReplicatedStorage.Shared
local T = game.ServerStorage.ShopTests
local Rules = require(S.ProgressionRules)
local Repository = require(S.ProgressionRepository)
local Config = require(S.ProgressionConfig)
local Catalog = require(Shared.CosmeticCatalog)
local Assets = require(Shared.CosmeticAssets)
print(require(T["ShopTransactions.spec"])(Rules, Repository, Config, Catalog))
print(require(T["CosmeticAssets.spec"])(Assets, Catalog))
print(require(T["ShopService.spec"])(S.ShopService.Source, Rules, Catalog, Assets))
print(require(T["ShopUI.spec"])(C.ShopUI.Source, Catalog, Assets))
print(require(T["CosmeticApplication.spec"])(S.CosmeticService.Source, C.CourtCosmetics.Source, Assets))
```

Remove temporary fixtures afterwards. These tests supply fake storage and network boundaries; they do not call the production progression service or grant any real player currency.


### Existing-place startup compatibility

The canonical catalog and visual builder now live in `src/server/Cosmetics`, which is included by the existing server directory mapping. The bootstrap clones missing modules into `ReplicatedStorage.Shared` before requiring progression/shop services, preserving already-mapped copies. This prevents an absent Shared catalog from stalling both the boutique and front-desk check-in. The expanded SharedModuleStartup fixture covers this exact missing-mapping scenario and idempotent reuse.

Startup fix verified in the connected Studio playtest: both enabled ProximityPrompts and both remotes existed; a real E keypress at the boutique opened PaddleUpShop, and a real E keypress at reception opened Daily Check-In. No purchases or claims were made. Studio API access remained disabled, so profile transactions reported the existing data-access error. The playtest was stopped afterward. The expanded SharedModuleStartup fixture, Rojo build and whitespace checks passed.
