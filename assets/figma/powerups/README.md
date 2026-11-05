# Uploaded powerup artwork

These SVG originals are the source of truth for powerup artwork. Roblox uses the
transparent PNG conversions in `generated/`; `manifest.json` records their sources
and dimensions. Runtime asset IDs are registered in `src/client/FigmaAssets.luau`.

`card_selected.svg` and `card_notselected.svg` include example powerup icons,
names, and placeholder descriptions. Their reusable `generated/cardFrame*.svg`
derivatives retain the original border, lightning, button outline, and selected
checkmark. The game adds the appropriate icon, name, effect, and action label.
The original complete card designs are also preserved as PNG previews.

The Small Paddle file is a standalone icon and is rendered in the same icon slot
as the other seven powerups. All icon rendering preserves aspect ratio.
