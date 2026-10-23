# XP, daily check-in, and seven-day rewards

The existing place uses `src/server/init.server.luau` for authoritative scoring, practice, roster changes, and rematches. It had no player progression or persistent reward data. The reception group `Check In` in `Lobby.luau` already contains a reception desk/stone top and CHECK IN sign. The new service attaches an E ProximityPrompt to that existing table after `Lobby.build()`, including saved lobbies, without rebuilding furniture.

## Rewards and tuning

All settings live in `src/server/ProgressionConfig.luau`; clients never choose reward values or submit earned XP.

XP needed to advance from level L is:

`100 + 50 * (L - 1) + 10 * (L - 1)^2`

Players start at level 1 with 0 XP. Requirements begin at 100, 160, 240, 340, and 460 XP. Earned XP carries across level thresholds, including multiple level-ups. The profile and calendar display current level and XP within that level versus the next requirement; progress fills animate, and a reward/level notification appears after confirmation.

| Event | Base XP |
| --- | ---: |
| Daily check-in | 150 |
| Qualified multiplayer completion, losing side | 80 |
| Qualified multiplayer completion, winning side | 120 total |
| Qualified practice game completion | 30 |
| Every 7 consecutive daily check-ins | 20% of the current level requirement |

Gameplay eligibility requires an actual game ending at the existing 11-point/win-by-two boundary, at least 90 seconds, at least 12 contested rallies (serve plus two valid player/bot returns), the correct complete roster, and at least 6 valid returns by the rewarded player. Leaving early, idle players, joins, menu actions, serve timeouts, difficulty resets, and roster changes earn no XP. A new roster or rematch starts a fresh reward run. A completed practice game can be won by either the player or the bot. There is no reward for merely exiting practice. This keeps new XP hooks off the scoring/physics path and avoids a farmable per-click or per-rally payout.

A check-in activates **+5% gameplay XP (1.05x)** through the end of the selected local calendar day. Configure `DailyMultiplier` in `ProgressionConfig.luau`; the UI percentage comes from the server. Existing claimed days use the updated multiplier for future eligible gameplay without changing previously awarded XP or saved streaks. Gameplay earned before the check-in transaction validates is not boosted, including while a claim is pending. The check-in itself and weekly bonus are not multiplied by default. Both have explicit configuration flags. Gameplay XP is capped at 600 **after** multipliers per player per selected local calendar day; check-in and weekly XP do not consume this cap. Repeated completed games after the cap do not produce unnecessary writes. Eligibility reduces trivial farming but cannot eliminate coordinated human collusion; the daily cap limits its benefit.

## Calendar and streaks

All servers use authoritative Unix timestamps and the player's persisted IANA time zone (UTC by default). Civil-day numbers are calculated with the server's bundled UTC offsets; weekday/date labels are formatted from that same civil day. The client never supplies a date. Reset is the next midnight in the selected zone, accounting for daylight saving. The interface displays Monday-Sunday cards, their states, the selected zone, and the next local reset.

Weekly rewards mean **seven consecutive check-ins**, not a calendar-week reset. Days 7, 14, 21, etc. in a continuous run each award once, even across Monday/Sunday boundaries. Missing a day breaks the active streak; the next claim starts at 1. No retroactive claims are possible. The daily reward is applied first, then the weekly bonus is calculated as `floor(currentLevelRequirement * 0.20)` immediately before that bonus is granted. For a requirement of 460 XP, the bonus is 92 XP. The preview can change if the daily reward first levels the player up; the UI explains that the grant uses the current requirement.

History retains the last 35 days, sufficient for the displayed calendar; lifetime weekly award count and the latest weekly reward date remain persisted. The active multiplier expiration is persisted and becomes inactive automatically at its saved local-midnight instant without requiring an extra save.

## Persistence and security

`ProgressionRules.luau` contains pure date, streak, reward, validation, and progression transitions. `ProgressionRepository.luau` commits against the latest record using `UpdateAsync`. `ProgressionService.luau` owns the store, per-player ordered work queues, prompt validation, remotes, and lifecycle. `MatchRewards.luau` tracks gameplay eligibility only. `ProgressionUI.luau` renders the server's snapshots and sends Sync, Retry, Claim, Close, and validated SetTimeZone actions.

The store is `PaddleUpProgression_v1`, keyed by `player_<UserId>`. Its versioned record persists level, current/lifetime XP, last claimed civil day, streak, check-in history with activation timestamps/multipliers, multiplier expiration, weekly award count/latest reward day, per-day gameplay budgets, and recent operation receipts. There is no stale cached-profile SetAsync save. Every confirmed award is already committed, so leaving or shutdown does not need to overwrite a profile snapshot. Concurrent instances merge against the latest record. There is no global server registry or gameplay dependency on cross-server messaging.

A stable server-generated operation ID survives retries. Receipts are retained for 48 hours; operations older than that are rejected, so expired IDs cannot replay XP. Check-in and weekly deduplication additionally use the saved claim date and streak state. Live receipts are never evicted to make room; the bounded receipt count fails safely if exhausted. Update callbacks have no remote calls, XP side effects, or yields. Failed writes may have unknown outcomes, so retries use the same ID and return the saved receipt if the first write actually committed.

Loading errors and invalid/future-schema data never become replacement defaults. Progression and claims are disabled until data is validated. Pending transactions retry with bounded exponential backoff and a later retry while connected; unconfirmed progress is not shown as earned. Departing players get a bounded opportunity to finish pending writes, and BindToClose stops new requests and drains pending transactions for up to 25 seconds. A prolonged outage, server crash, or Roblox's shutdown deadline can still prevent an **unconfirmed** reward from completing; the system does not promise delivery of unsaved work. Existing committed progress is never replaced by defaults, and a committed claim cannot pay twice on retry/rejoin. Failed operations are logged.

The server requires a recent server-opened desk interaction, Lobby mode, a living avatar, and actual proximity before claiming, regardless of client prompt settings. Requests are rate-limited; the UI cannot award arbitrary XP, set dates, choose levels, or claim missed days. Repeated desk openings refresh the stored record at most once per 30 seconds; claims always validate atomically against the latest stored record. A stale display from another instance therefore cannot authorize an extra reward.

## UI and controls

The profile sits at the upper right below the existing leave button. The check-in modal uses the current Gotham Bold, indigo/cyan palette, rounded panels, and short tweens. It scales to the viewport and includes all seven horizontal day cards, current XP and level, a streak indicator, reward/multiplier details, weekly preview, claim/checked-in states, and reset time. E opens it at reception; Roblox also supplies touch interaction and gamepad X. Close, Escape, or gamepad B dismiss it. Escape may also open Roblox's standard system menu. Changing out of Lobby mode closes it. The lobby orbit camera respects modal focus.

## Configuration and verification

No Open Cloud key, HTTP permission, MemoryStore, extra place, or new asset upload is needed. Publish the Rojo project to the intended test experience. For Studio DataStore testing, enable **Game Settings / Experience Settings -> Security -> Enable Studio Access to API Services** on a published **test** experience. Studio DataStore access can touch that experience's actual saved keys; keep it separate from production data. Published server DataStore access uses Roblox's server API; the Studio-access toggle controls Studio testing. Confirm publication/access permissions and test with normal Roblox player accounts before rollout.

References: [Roblox data stores](https://create.roblox.com/docs/cloud-services/data-stores), [UpdateAsync/retry best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices), [unknown write outcomes](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits), [ProximityPrompt security](https://create.roblox.com/docs/scripting/security/client-server-boundary).

Automated fixtures:

- `ProgressionRules.spec.luau`: level-ups, immutable transitions, daily claim deduplication, multiplier timing/expiry, missed days, seven/fourteen-day runs across calendar weeks, exact weekly calculation, calendar states, expired/backdated claims, corrupt data, and gameplay caps.
- `ProgressionRepository.spec.luau`: fake atomic backend, repeated transform callbacks, commit-with-lost-response retries, cross-server duplicate operations, rejoin state, throttling/load failure, invalid saved data preservation, and shutdown deadlines.
- `MatchRewards.spec.luau`: completion, win/loss/practice rewards, minimum activity, repeat completion, roster changes, idle players, and timeouts.
- `ProgressionService.spec.luau`: real service with fake storage and detached desk/avatar objects, verified loading, duplicate startup, E prompt configuration, interaction and distance checks, repeated claims, boost, departures, and shutdown.
- `ProgressionUI.spec.luau`: real interface rendered into a detached folder with fake network/input, seven day cards, level/current/required XP, animated progress fill, reward notifications, duplicate startup, and Escape close.

Existing launch/scoring, jump-slam, queue admission, shared-module startup, and Low Gravity fixtures should also pass. The tests do not require or use live DataStores. To run in Studio, import the progression fixtures as ModuleScripts into a temporary `ServerStorage.ProgressionTests` folder in a test copy, with names matching the filenames without `.luau`. Run from Studio's command bar/Luau executor:

```lua
local S = game.ServerScriptService.Server
local T = game.ServerStorage.ProgressionTests
local M = {}
for _, name in ipairs({"TimeZones", "ProgressionConfig", "ProgressionRules", "ProgressionRepository", "MatchRewards"}) do
    M[name] = require(S[name])
end
print(require(T["TimeZones.spec"])(M.TimeZones, M.ProgressionRules, M.ProgressionConfig, M.ProgressionRepository))
print(require(T["ProgressionRules.spec"])(M.ProgressionRules, M.ProgressionConfig))
print(require(T["ProgressionRepository.spec"])(M.ProgressionRepository, M.ProgressionRules, M.ProgressionConfig))
print(require(T["MatchRewards.spec"])(M.MatchRewards, M.ProgressionConfig))
print(require(T["ProgressionService.spec"])(S.ProgressionService.Source, M))
print(require(T["ProgressionUI.spec"])(game.StarterPlayer.StarterPlayerScripts.Client.ProgressionUI.Source, M.ProgressionRules))
```

Source-extraction fixtures need loadstring support in the test executor. Do not ship test fixtures or enable unrestricted loadstring in production.

Manual Studio acceptance still needed: use Server & Clients with two players; walk to the existing reception table, press E, claim once, reopen, inspect all claim states and notifications, and test close/Escape/controller/touch and narrow viewports. Complete a qualified match and practice game and verify the server-confirmed XP updates. Reset difficulty or leave early and confirm no completion award. Use fake clocks/backends for seven-day and outage scenarios; do not add a client clock or reward override to production.

**Published-experience acceptance is required before claiming persistence works:** join the test experience in the Roblox client, claim, complete a qualifying game, leave, and rejoin (including a different public server). Inspect the saved record/server logs and verify matching XP/level, one daily claim, unchanged weekly claim state, and the correct selected-zone expiration. Exercise repeated clicks and concurrent sessions; observe a real selected-zone midnight. Use test-only seeded server data or the fake-clock fixtures for seven-day runs, never a production client override. Disable/restore API access only in a test copy to verify failures do not overwrite saved data or enable claims.

At implementation time, live persistent saving, live cross-server behavior, actual E-key interaction in a running multi-client session, and visual/mobile playtests have **not** been validated. Automated fake-store tests establish code behavior, not Roblox backend availability or successful published persistence.

## Changed files

New modules: `src/server/ProgressionConfig.luau`, `ProgressionRules.luau`, `ProgressionRepository.luau`, `ProgressionService.luau`, `MatchRewards.luau`, and `src/client/ProgressionUI.luau`.

Integration: `src/server/init.server.luau`, `src/client/init.client.luau`, `src/client/LobbyCamera.luau`. No furniture, scoring rules, existing UI, or place mappings were replaced.

New tests: `tests/ProgressionRules.spec.luau`, `ProgressionRepository.spec.luau`, `MatchRewards.spec.luau`, `ProgressionService.spec.luau`, `ProgressionUI.spec.luau`.

Documentation: `PROGRESSION.md`, `README.md`.

## Verification record

Implementation checks passed: all 84 source/test files compiled as Luau; the Rojo build of `default.project.json` passed; `git diff --check` passed. Ten regression fixtures passed: ProgressionRules, ProgressionRepository, MatchRewards, ProgressionService, ProgressionUI, PowerupServer, JumpSlamServer, SharedModuleStartup, MatchQueueAdmission, and LowGravity. Tests ran through the Studio Luau executor using fake stores/services and detached test objects; no live DataStore calls were made. The open place's scripts, API settings, and published experience were not changed by these tests.

Live saving, multi-client interaction, and visual/mobile acceptance remain unverified as described above.

## Daily Check-In refinement and loading fix

The connected Studio Output log identified the original failure exactly: `StudioAccessToApisNotAllowed` / HTTP 403 on `UpdateAsync` for `PaddleUpProgression_v1`. Studio API access was disabled. The UI repeated the same error in its summary/footer, rendered placeholder day cards, and kept a disabled PLEASE WAIT button. Sync did not force recovery of a failed transaction when cached player data existed, and the original UI had no explicit Retry action. Several intended symbols had also been stored as literal question marks.

The existing panel now leads with TODAY'S REWARD, +5% BONUS XP, its eligible-gameplay explanation, and CHECK IN & ACTIVATE. Confirmed claims show a checkmark and active-until-midnight message. The separate 150-XP check-in grant remains visible as secondary information; the weekly formula and consecutive-day rules are unchanged. Calendar dates/statuses render only after validated server data arrives. Seven gold segments show WEEKLY STREAK: X/7 DAYS, and weekly completion is confirmed by the saved weekly reward date. Narrow layouts keep text/card sizes readable and scroll the calendar horizontally. Symbols use explicit Unicode codepoints so shell/text encoding cannot turn them into question marks.

One status area handles initial loading, errors, and slow responses. Error states offer Retry and keep claiming disabled. Permanent configuration/validation failures stop automatic retry loops; transient errors retain bounded retries. Manual Retry reuses the original queued transaction ID, works even with cached data, and cannot start a second in-flight write. The UI surfaces a slow request after 15 seconds, including a write whose periodic status packets continue arriving. Retrying never cancels/duplicates that write or substitutes fake data.

Per-player monotonically increasing packet revisions reject stale snapshots. Request acknowledgements preserve pending actions, and desk interaction IDs prevent a late opening packet from reopening a dismissed modal. Repeated prompt triggers cannot repeatedly open the same interaction.

**Configuration still required:** in a published test copy, open File -> Experience Settings -> Security, enable **Enable Studio Access to API Services**, save, and use Retry (or restart the test). API permissions and publishing were not changed by this task. Do not enable Studio access on production data just to preview the UI. See [Roblox Studio DataStore access](https://create.roblox.com/docs/cloud-services/data-stores#enable-studio-access) and [error 403](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits). A code change cannot authorize a disabled Roblox API.

Files changed for this refinement: `src/client/ProgressionUI.luau`; `src/server/ProgressionConfig.luau`, `ProgressionRules.luau`, `ProgressionRepository.luau`, `ProgressionService.luau`; `tests/ProgressionRules.spec.luau`, `ProgressionService.spec.luau`, `ProgressionUI.spec.luau`; and `PROGRESSION.md`. No furniture, gameplay eligibility, score logic, XP curve, or weekly bonus formula was changed.

Refinement validation: all ten listed regression fixtures passed again, including the expanded loading/retry, stale-response, phone-layout, rejoin, and seven-day cases. All 84 Luau source/test files compiled; Rojo build and whitespace checks passed. These checks used fake storage and detached objects, not live persistence or a published visual playtest.

## Historical UTC calendar investigation (superseded by player time zones)

Read-only inspection of `PaddleUpProgression_v1` in Paddle Up - Dev Testing (place 84449123874000, universe 10772479357) found these existing version-1 entries:

| Saved UTC day | Claim timestamp (UTC) |
| --- | --- |
| 2026-10-22 Thursday (epoch day 20748) | 2026-10-22 23:52:20 |
| 2026-10-23 Friday (epoch day 20749) | 2026-10-23 00:01:11 |

The Friday claim occurred after midnight UTC. In New York it was still Thursday, October 22 at 8:01:11 PM EDT. This was a valid Friday UTC check-in, not an early future-day reward. The record's streak was 2 and multiplier expiration was 2026-10-24 00:00:00 UTC. No record was edited, reset, migrated, or saved during the investigation.

All reward dates already use server `DateTime.now()` Unix timestamps, `floor(timestamp/86400)`, and explicitly UTC `os.date` formatting with the `!` prefix. The client renders the server's labels; it neither parses ISO strings nor computes a local weekday or eligibility date. Check-in requests do not accept a target date. The atomic transition rejects requests whose earned calendar day differs from the transaction's current UTC day. Reconnecting or switching servers does not move a saved UTC day.

The targeted clarification displays **TODAY: FRI, OCT 23 (UTC)** above the calendar on both desktop and narrow layouts. Future cards always remain Upcoming, even if an existing record contains a future history entry; that history is preserved. A separate midnight edge was corrected: snapshots previously sampled `now()` once for the calendar and again for the published clock, so a snapshot spanning midnight could briefly pair Thursday's calendar with Friday's `serverNow`. Both now use one captured timestamp. Gameplay eligibility/cap checks and queued award timestamps also share one captured server time, as do the preliminary claim-date check and its queued transaction. Atomic validation still rechecks the actual transaction time.

Added `tests/CheckInUTC.spec.luau` covering Thursday 23:59:59 UTC versus Friday 00:00:00 UTC, rejected future dates, reset/boost expiration, matching UTC weekday/date labels, repeat claims, mocked rejoining/cross-server claims, seventh-day reward timing, preserved future history, and a snapshot clock crossing midnight. The existing service and UI fixtures also cover a client-supplied future date being ignored and UTC labels updating on a phone layout without any client `os.date` calls. To run the additional fixture with the test setup above:

```lua
print(require(T["CheckInUTC.spec"])(M.ProgressionRules, M.ProgressionConfig, M.ProgressionRepository, S.ProgressionService.Source))
```

UTC validation passed: six progression/date/service/UI fixtures, all 85 Luau source/test syntax checks, Rojo build, and whitespace validation. Midnight tests use controlled clocks and fake stores; they do not change the live clock or saved records. XP values, the +5% gameplay bonus, level requirements, seven-day rules, and weekly formula remain unchanged. Files changed for this task: `src/server/ProgressionRules.luau`, `src/server/ProgressionService.luau`, `src/client/ProgressionUI.luau`, new `tests/CheckInUTC.spec.luau`, `tests/ProgressionService.spec.luau`, `tests/ProgressionUI.spec.luau`, and `PROGRESSION.md`.

## Player-selected local time zones

The UTC investigation above describes the previous implementation. The current system uses a persistent player setting selected through the **TIME ZONE** control in the existing check-in panel. The searchable picker lists all 419 city/region entries from IANA `zone.tab`, plus UTC in that total. UTC remains the default so existing players keep their established reset until they explicitly choose another zone. The game does not guess a location or trust the client's clock, offset, date, or reward eligibility.

`TimeZones.luau` uses server-only offsets generated from **IANA 2026e** (the pinned, SHA-256-verified `tzdata` 2026.5 wheel). Roblox's [DateTime APIs](https://create.roblox.com/docs/reference/engine/datatypes/DateTime) expose system-local and universal formatting rather than an arbitrary IANA-zone conversion API. Bundled transitions avoid a runtime HTTP dependency. They support 2020 through 2040, including fractional offsets and DST transitions. Out-of-range non-UTC dates fail closed, with an update-required error; they never silently assume a fixed offset. Future government rule changes require regenerating and republishing the data. Run `python tools/generate_time_zones.py`; when updating the release, review its pinned version, wheel URL, and SHA-256 first. The generator verifies explicit TZif offset-changing transitions against its output. Sources: [tzdata releases](https://github.com/python/tzdata/releases), [pinned package](https://pypi.org/project/tzdata/2026.5/), [IANA releases](https://data.iana.org/time-zones/releases/).

Calendar cards, today's date, claim validation, next reset, gameplay daily budget, streak progression, and weekly rewards derive from the saved zone and server timestamp. Claim history stores the zone, civil day, activation timestamp, and absolute expiration. Calendar history projects actual confirmed claim instants into the selected zone. Changing zones cannot fabricate a completed day. A boosted reward must have been earned within a saved claim's absolute activation/expiration window. Zone changes do not extend it or boost earlier gameplay. The +5% multiplier, 150-XP daily grant, level curve, 600-XP daily gameplay cap, and seven-day 20% weekly formula are unchanged.

**Zone-change policy:** an initial selection before any check-in applies immediately. Changes after a claim take effect at the next midnight in the currently active zone. Changes are limited to once every seven elapsed days (`TimeZoneChangeDays` in the existing config). The next claim must be after both the previous claim's absolute expiration and the midnight following that claim in the new zone. Moving across zones therefore cannot unlock another reward on the same local claim day or shorten an existing reward window. The next eligible day bridges a deferred zone transition for streak continuity; missing that eligible day resets the streak. The server atomically validates the allowlisted zone, cooldown, and latest profile. Existing proximity, interaction, rate-limit, duplicate-operation, and stale-response protections also apply.

**Migration and rollout:** schema version 2 uses the SAME `PaddleUpProgression_v1` store and player keys. Loading uses the existing `UpdateAsync` path to migrate version-1 records, preserving XP, level, streak, weekly counts, receipts, budgets, legacy UTC history, and multiplier deadlines. Legacy claims become auditable UTC claim windows; the original history remains intact. Invalid or newer-schema data is never replaced with defaults. No actual player record was migrated or written during implementation; migration was tested only against fake stores, including a fixture matching the inspected record. Publish all modules together and restart older servers during rollout: old version-1 code rejects version-2 records safely but cannot use the new schema. No additional Dashboard permissions, places, HTTP requests, or external service credentials are required.

Changed for this update: `src/server/TimeZones.luau`, generated `TimeZoneData.luau`, `tools/generate_time_zones.py`, existing `ProgressionConfig.luau`, `ProgressionRules.luau`, `ProgressionRepository.luau`, `ProgressionService.luau`, `src/client/ProgressionUI.luau`, `tests/TimeZones.spec.luau`, the existing service/UI fixtures, and this document.

Automated verification uses controlled server clocks and fake stores: different zones on the same instant; all 419 zones' reset boundaries; New York and London 23/25-hour days; Sydney and Lord Howe DST, including 23.5/24.5-hour days; repeated fall-back hours; midnight expiration; seven consecutive local days across DST; missed days; exact weekly rewards; rejected future/duplicate claims; preserved version-1 migration; deferred changes/cooldowns; rejoining and cross-server duplicates; invalid/stale/distant setting requests; searchable picker selection and server-provided labels with client date functions disabled. These fixtures do not prove live DataStore availability. Published rejoin/cross-server persistence, two-client interaction, and visual phone/controller playtests remain required before rollout. Test those in the separate published test experience with Studio API access configured if using Studio; do not seed or reset production player progress.

Local-zone verification passed: all 87 Luau source/test chunks compiled; seven progression/repository/match/date/service/UI fixtures passed through the Studio Edit executor; Rojo build and `git diff --check` passed. The generator verified its pinned archive hash and all explicit in-range TZif offset transitions. Tests used detached objects and fake stores; no live scripts, API settings, or player data were changed.
