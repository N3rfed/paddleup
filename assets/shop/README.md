# Paddle Up shop artwork and previews

The six visible paddle prints are Pickle Club, Catnap Club, Flame Court, Love Rally, Checkerboard, and Lotus Lake. Noir is retained for existing owners. Each print is a single 1024 x 1280 PNG, applied once to each actual paddle face. Carbon edge geometry stays behind the printed face; it does not overlap the artwork. No paddle dimensions, hitboxes, or gameplay grip geometry are changed.

Run python tools/generate_shop_art.py to regenerate the print source assets and contact sheet. Uploaded asset references live in src/server/Cosmetics/CosmeticTextures.luau.

Outfits use the standard Roblox Man and Woman R15 body packages and Roblox hair in ShopMannequins.luau. Accessory welds are resolved before the rigs are anchored. Male/female outfit variants share five palettes: white, black, pink, Pickle Club, and Flame Court. Outfits include matching headbands; standalone headbands are available in the same five palettes. Headband thumbnails use cropped headshots.

CosmeticAssets uses fitted, nonphysical copies of existing body meshes for apparel. Original clothing, clothing accessories, and body colors are restored on unequip. Existing catalog IDs and prices are retained, and owned legacy items remain accessible. The existing single Wearables slot is preserved: an outfit includes its matching band, while choosing a standalone band replaces the outfit selection.

The server republishes canonical cosmetic modules and clients wait for CosmeticsVersion 2 before requiring them. This prevents saved stale Shared modules from showing older designs in Studio.

Verification: CosmeticAssets, CosmeticApplication, ShopTransactions, ShopService, and ShopUI suites passed in Studio using the existing injected-source harness. Visual checks covered all six paddle prints, both R15 outfit fits, and headband previews. The test shop's real DataStore writes are unavailable because Studio API access is disabled; transactions were exercised with the existing fake repository tests instead. No live player profile was modified to perform visual checks.

Catnap Club uses the existing paddle_tour item ID and price so previous owners retain it. Lotus Lake is a new 360 XP item (paddle_lotus), featuring a pink lotus, lily pads, and a jade lake. Both are original single-print artwork with the same non-overlapping face renderer.
