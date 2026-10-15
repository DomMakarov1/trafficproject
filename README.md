# Terraform

An upgrade-tree idle game for Roblox. You grow a barren plot into a living garden: every
upgrade you buy visibly changes the world, some upgrades are hidden `???` until you meet a
secret condition, and each prestige layer (Bloom) changes the rules.

## Run it
1. Install [Rojo](https://rojo.space) (`aftman install rojo-rbx/rojo` or the Studio plugin).
2. Open an empty Baseplate place in Studio (delete the default Baseplate part).
3. `rojo serve` in this folder, then click **Connect** in the Rojo Studio plugin.
4. Press Play. In Studio, enable *Game Settings → Security → Enable Studio Access to API Services* to test saving.

## Layout
- `src/shared/Nodes.lua` – **every upgrade lives here.** Add a table entry to add content.
- `src/shared/Config.lua` – economy tuning, game pass IDs.
- `src/server/PlayerState.lua` – economy, buying, Bloom, mystery reveals, offline earnings.
- `src/server/PlotBuilder.lua` – builds each player's garden and decorations from code.
- `src/server/Main.server.lua` – join/leave, saving, game loop.
- `src/client/Hud.client.lua` – HUD and toasts.

## Layer 1 content
Seeds tree (10 upgrades + 3 mystery), Bloom prestige, Petal tree (3 upgrades), pollination
mechanic (after first Bloom, neighbouring owned upgrades boost each other).

## Monetization
Set real game pass IDs in `Config.Passes` (2x Seeds, Auto-Buy). Pads hide while ID is 0.
