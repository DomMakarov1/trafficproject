# Deep Line — Design Plan

A relaxed fishing and exploration game for Roblox. Start on a sleepy harbor dock, and
end up piloting a submarine through the abyss, hunting fish nobody has seen before.

## Pillars

1. **Relaxed, never punishing.** No death penalty, no lost catches, no timers you can fail.
   Skill makes you better off, not worse off for lacking it.
2. **There's always something deeper.** Vertical progression is the hook. Each depth
   tier is darker, stranger and more mysterious than the last.
3. **Show it off.** Rare fish, mutations, a bestiary to complete and an aquarium to
   display your best catches in.

## Core loop

```
Cast → Bite → Reel (minigame) → Catch → Keep or Sell → Upgrade gear → Go deeper → Rarer fish
```

A session should feel good at 5 minutes (a few casts, one upgrade) and at 2 hours
(push into a new zone, chase a specific rare fish).

## Fishing

### Cast
Hold to charge and release to cast. Cast distance matters little; it's mostly feel.

### Bite
After a short wait (shortened by bait and rod), a bite indicator appears. Tap within
a generous window to hook. Missing just means a longer wait, never a penalty.

**The server rolls the fish at bite time.** The client never chooses what it caught.

### Reel minigame
- A fish icon drifts along a track. Hold to raise your catch zone and release to let it fall.
- Keep the fish inside the zone to fill the progress bar. Outside it, progress drains slowly.
- **Starter zones:** fish never escape; a sloppy catch just takes longer.
- **Deeper zones:** escape becomes possible, but the line strength upgrade softens it.
- **Perfect catch** (fish never left the zone) gives a value bonus and a satisfying effect.
- One-thumb friendly. Most Roblox players are on mobile.

## World: depth tiers

| Tier | Zone | Depth | Access | Vibe |
|---|---|---|---|---|
| 0 | Harbor | Surface | Start | Warm, sunny, lanterns at night. Shops and hub. |
| 1 | Kelp Shallows | 10–50 m | Rowboat | Swaying kelp, otters, calm. |
| 2 | Coral Reef | 50–200 m | Motorboat | Colorful, busy, lots of species. |
| 3 | Twilight Zone | 200–1,000 m | Submarine Mk I | Light fades. Your lantern starts to matter. |
| 4 | Midnight Zone | 1,000–4,000 m | Submarine Mk II | Pitch black, bioluminescent, eerie. |
| 5 | The Abyss | 4,000 m+ | Pressure Sub | Ruins, lore, legendaries. Endgame. |

**Depth is gated by vessel, not by danger.** Diving to a new tier is a short descent
transition (fade, depth counter ticking down, bubbles) into that zone's area. This avoids
simulating deep-water physics and keeps each zone's lighting fully art-directed.

**Light is a mechanic from Tier 3 onward.** A brighter lantern attracts more fish and
reveals rare species that only appear in light radius. Some Midnight Zone fish flee light
instead, so the lantern color and intensity become a light strategic choice.

## Fish

### Data per fish
- Name, zone, rarity, base value, weight range (kg)
- Conditions: time of day (day / night / any), weather, required bait (optional)
- Bestiary flavor text

### Rarity
| Rarity | Base weight | Notes |
|---|---|---|
| Common | 60 | |
| Uncommon | 25 | |
| Rare | 10 | Server announcement |
| Epic | 4 | Server announcement |
| Legendary | 0.9 | Global announcement and effect |
| Mythic | 0.1 | One or two per zone. Chase targets. |

Luck from gear and bait shifts weight upward along the rarity table.

### Mutations
Rolled independently after the fish is chosen.

| Mutation | Chance | Value | Condition |
|---|---|---|---|
| Shiny | 1 / 50 | ×2 | Any |
| Giant | 1 / 100 | ×3 weight | Any |
| Albino | 1 / 200 | ×3 | Any |
| Glowing | 1 / 40 | ×2.5 | Night only |
| Abyssal | 1 / 75 | ×4 | Midnight Zone and deeper |

### Harbor starter set (milestone 1)
| Fish | Rarity | Condition |
|---|---|---|
| Dock Minnow | Common | Any |
| Sardine | Common | Any |
| Mackerel | Common | Day |
| Old Boot | Common (junk) | Any |
| Harbor Crab | Uncommon | Any |
| Flounder | Uncommon | Any |
| Sea Bass | Uncommon | Day |
| Pufferfish | Rare | Any |
| Moon Jelly | Rare | Night |
| Message in a Bottle | Rare | Any. Unlocks a lore page. |
| The Dockmaster (giant grouper) | Legendary | Night, special bait |

## Gear and progression

| Slot | Affects |
|---|---|
| Rod | Luck, bite speed |
| Reel | Reel speed (catch zone size) |
| Line | Escape resistance in deeper zones |
| Bait | Targets rarity or a specific species. Consumable. |
| Vessel | Depth tier access, storage capacity |
| Lantern | Light radius and color (Tier 3+) |

Coins come from selling fish. Some upgrades also need a specific catch
("Bring me a Pufferfish"), which gives goals beyond grinding coins.

## Collection and show-off

- **Bestiary:** every species, with silhouettes for undiscovered ones. Completion rewards per zone.
- **Aquarium:** a personal space where you display fish. Other players can visit.
- **Catch announcements:** Rare and above get announced in chat, Legendary and Mythic
  get a global effect.
- **Records:** heaviest catch per species on a leaderboard.

## Time, weather and events

- **Day/night cycle:** about 20 minutes per full day. Many fish are day-only or night-only.
- **Weather:** clear, rain, fog, storm. Some species only bite in specific weather.
- **Server events:** examples are a whale migration, a meteor shower (star-touched mutation)
  or a bioluminescent bloom. They're short, visible to everyone and bring limited-time fish.
- **Tournaments:** hourly, e.g. "heaviest Sea Bass in 10 minutes". Cosmetic rewards.

## Social

- Shared submarines: a 2–4 seat vessel lets friends dive together.
- Aquarium visits.
- Trading (post-launch; needs careful anti-dupe work).

## Monetization

Keep it non-pay-to-win and relaxed.

- **Game passes:** extra bait slot, bigger aquarium, vessel skins, 2× storage.
- **Developer products:** server-wide luck totem for 15 minutes. It helps everyone,
  so buyers are thanked rather than resented.
- **Cosmetics:** rod skins, boat paint, lantern colors, fishing hats.
- **No paid random items.**

## Technical architecture

### Tooling
- **Rojo** for syncing files to Studio
- **Wally** for packages
- **Selene** (lint), **StyLua** (format), **luau-lsp** (types)
- Strict Luau type checking (`--!strict`) on shared and server code

### Layout
```
src/
  server/
    Services/
      DataService.luau       -- ProfileStore: load, save, session lock, schema versions
      FishingService.luau    -- bite timing, fish roll, catch validation
      InventoryService.luau
      EconomyService.luau    -- selling, purchases
      ZoneService.luau       -- tier access, descent transitions
      WorldService.luau      -- day/night, weather, events
  client/
    Controllers/
      FishingController.luau -- cast, bite, reel minigame
      UIController.luau
      ZoneController.luau    -- per-zone lighting and atmosphere
  shared/
    Config/
      Fish.luau
      Zones.luau
      Gear.luau
      Mutations.luau
    Util/
      WeightedRandom.luau
    Net.luau                 -- typed remote wrapper with rate limiting
```

### Server authority
The game is relaxed, but coins, leaderboards and later trading all need an honest economy.

1. The client requests a cast. The server starts the bite timer.
2. The server rolls the fish, weight and mutations when the bite fires, and stores
   the pending catch.
3. The client plays the minigame and reports the result.
4. The server validates the report: the elapsed time is plausible for that fish,
   there's one pending catch, and the player is in the right zone. Only then is
   the catch granted.

The client never sends which fish it caught or what it's worth.

### Data
- ProfileStore with session locking.
- Schema version field and a migration function from day one.
- Stored: coins, inventory, gear, bestiary, aquarium layout, records, settings.

### Performance
- Fish in the water are client-side visuals only. The server knows only about pending catches.
- Each zone is its own region with streaming enabled.
- Mobile first: test UI and minigame on a phone-sized viewport throughout.

## Milestones

| # | Milestone | Done when |
|---|---|---|
| M0 | Project setup | Rojo project builds and syncs into Studio. Lint and format pass. |
| M1 | Core loop slice | On the Harbor dock you can cast, reel, catch the 11 starter fish, sell them, and your coins save between sessions. |
| M2 | Progression | Rod, reel and bait shop. Rowboat and motorboat. Kelp Shallows and Coral Reef. Bestiary. ~30 fish. |
| M3 | Depth | Submarines, Twilight and Midnight Zones, the lantern mechanic, mutations, day/night and weather. |
| M4 | Show-off | Catch announcements, aquarium, records leaderboard, tournaments. |
| M5 | Launch | The Abyss, onboarding tutorial, monetization, mobile pass, performance pass. |
| Post | Live | Trading, server events, new zones and seasonal fish. |

## Open questions

- Art style (low-poly stylized is the default assumption: cheap to build, reads well on mobile)
- Solo or with a builder/modeler?
- Target launch timeline
