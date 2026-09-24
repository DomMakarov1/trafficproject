# Muck Crew — Design Plan

*Working title.* A cozy co-op cleanup game for Roblox, inspired by the loop of Sludgineers
(clean, refine, upgrade, reach new areas) and rebuilt as 3D and multiplayer with its own
identity. No names, art or assets are taken from Sludgineers.

## Pitch

The world is buried in toxic gunk. You and up to three friends grab backpack vacuums,
head out on cleanup jobs, and bring the land back to life one patch at a time. Back
at base, your refinery turns the muck into money.

## Pillars

1. **Cleaning feels great.** Suction, sound, the goo shrinking as you pull it in. This
   is the whole game, so it gets prototyped first.
2. **You can see the land recover.** Grey muck gives way to grass, flowers and
   animals. The world changing matters more than numbers going up.
3. **Better together, fine alone.** Every map can be played solo. Friends make it faster
   and open up co-op-only moments, but never feel required.
4. **Relaxed.** No fail states, no death. A run ends when you choose to head home.

## Game structure

```
Lobby (hub)                       Job (map)
┌──────────────────────┐ teleport  ┌───────────────────────────┐
│ Your garage/refinery │ ───────▶  │ Shared sludge, 1–4 players│
│ Upgrade shop         │           │ Vacuum → tank → van       │
│ Map board + party    │ ◀───────  │ Head home anytime         │
└──────────────────────┘  return   └───────────────────────────┘
```

- **Lobby:** where you live between jobs. Your refinery processes what you brought back
  and you spend the earnings on upgrades. You pick a map and party size here.
- **Job:** a private server for your party on the chosen map. The sludge is **shared**:
  everyone in the party sees and cleans the same muck.

The lobby itself (party size, invites, map select UI) will be designed later.
What is fixed now: party size is solo, 2, 3 or 4, and parties are formed by invite.

## Job loop

1. Spawn at the van on the map's edge.
2. Vacuum sludge. Your backpack tank fills up and your battery drains.
3. Walk back to the van to dump the tank and recharge. The van is your checkpoint.
4. The map's **cleanliness %** rises and the land visibly recovers.
5. Head home whenever you like. Everything dumped at the van comes with you.
   Reaching milestones (50%, 75%, 100%) pays out a team bonus.

The battery and tank limits set the rhythm of a run: a push out, a walk back, a new push.
Upgrades make each push longer and stronger.

### Rewards in co-op
- **Personal haul:** what you vacuum is yours.
- **Team bonus:** milestone payouts are split equally.

Nobody feels robbed when a friend cleans the patch they were heading for.

## Sludge

### Types
| Type | Needs | Yields | First appears |
|---|---|---|---|
| Slime | Vacuum | Sludge | Map 1 |
| Tar crust | Scraper attachment, then vacuum | Sludge, Tar | Map 2 |
| Toxic pool | Filter upgrade | Toxic sludge | Map 3 |
| Deep deposit | Drill attachment | Ore, rare metals | Map 3 |
| Oil slick (on water) | Skimmer attachment | Crude oil | Map 4 |

Each new type introduces a new tool and a new way to play, which answers the main
criticism of Sludgineers (repetition).

### Co-op spills
Giant sludge masses that only shrink under combined suction. Solo players can still
clear them with high-end gear, just slowly.

## Maps (first pass)

| # | Map | Theme | New sludge |
|---|---|---|---|
| 1 | Meadow Farm | Fields, barn, pond. Tutorial. | Slime |
| 2 | Old Town | Streets, alleys, a park | Tar crust |
| 3 | Quarry | Cliffs, tunnels, machinery | Toxic pools, deep deposits |
| 4 | Harbor | Docks, beach, shallow water | Oil slicks |
| 5 | The Plant | The factory that caused it all. Endgame. | All, plus a final co-op spill |

Maps unlock through progress on the previous map (cleanliness reached across runs) and
quests from lobby NPCs.

## Tools and upgrades

| Upgrade | Effect |
|---|---|
| Suction power | Sludge removed per second |
| Nozzle width | Size of the cleaning cone |
| Reach | Distance of the cone |
| Tank | How much you carry before dumping |
| Battery | How long you vacuum before recharging |
| Move speed | Faster trips to and from the van |
| Attachments | Scraper, filter, drill, skimmer (unlock new sludge types) |
| Van | Faster recharge, remote dump range |

## Refinery

Lives on your plot in the lobby, so other players can see it.

- Raw materials from jobs go into machines: **Separator → Distiller → Press**, and so on.
- Products: fuel, plastic pellets, fertilizer, metal ingots. They sell for more than raw sludge.
- Machines keep processing while you're out on a job. You come home to finished goods.
- Machines are upgraded and expanded, which adds a light tycoon layer.

## Monetization

- **Game passes:** bigger tank, refinery slots, van skins, vacuum skins.
- **Cosmetics:** suits, hats, vacuum colors, sludge-splat effects.
- **Developer products:** a crew-wide suction boost for one job (helps the whole party).
- **No paid random items**, and nothing required to finish maps.

## Technical architecture

### Places
- **Lobby place:** hub, refinery plots, shop, party and map selection.
- **Job place:** one place for all maps. The chosen map is loaded from `ServerStorage`
  at server start. One place means one set of code to publish and keep in sync.

The lobby creates a reserved server with `TeleportService:ReserveServer` and teleports
the party there. Job details (map, party members, party size) are written by the lobby
server to `MemoryStoreService`, keyed by the reserved server, and read by the job
server on start. Teleport data from the client is never trusted.

### Sludge system (not terrain)

**Server state: a grid.**
- Each map is covered by a grid of cells, about 2×2 studs each.
- Per cell: sludge type and amount (0–255), stored in Luau `buffer`s for compact memory.
- Ground height per cell is sampled once when the map loads, so sludge sits on the surface.
- The grid is split into chunks (for example 16×16 cells) for replication and rendering.

**Vacuuming is simulated on the server.**
- The client only says "I'm vacuuming, aiming here".
- The server checks position, reach and equipment, then removes sludge from the cells
  in the cone itself.
- The client plays suction effects immediately so it feels instant. The server's
  numbers are final.

**Replication.**
- Changed cells are batched per chunk and sent to clients about 10 times a second.
- Players joining mid-run receive a full snapshot, then deltas.

**Rendering (client).**
- Only chunks near the player are rendered, and only changed chunks are rebuilt.
- Start with pooled blob meshes per cell, scaled and faded by amount.
- Upgrade path to prototype: `EditableMesh` sludge surface per chunk, with vertex heights
  driven by the grid, for a continuous, gooey surface.
- Restoration: cells at zero swap the ground underneath to a "clean" look,
  and decorations (flowers, grass tufts) fade in over cleaned areas.

This is the riskiest system, so it's milestone 1.

### Tooling
Rojo, Wally, Selene, StyLua, luau-lsp, strict Luau on shared and server code.

### Layout
```
src/
  lobby/
    server/   PartyService, JobLaunchService, RefineryService, ShopService
    client/   LobbyUI, RefineryUI, MapBoard
  job/
    server/   JobService, SludgeService, VacuumService, VanService
    client/   SludgeRenderer, VacuumController, JobUI
  shared/
    Config/   Maps, SludgeTypes, Upgrades, Machines
    Services/ DataService (ProfileStore, used by both places)
    Util/     Grid, Net (typed remotes with rate limiting)
```

### Data
- ProfileStore with session locking, used in both places. Profiles are released before
  teleporting so the next place can load them.
- Schema version field and migrations from day one.
- Stored per player: coins, materials, upgrades, refinery state, map progress, quests,
  cosmetics.

## Milestones

| # | Milestone | Done when |
|---|---|---|
| M0 | Setup | Rojo project builds and syncs to Studio, lint and format pass |
| M1 | **Sludge prototype** | On a flat test map, vacuuming sludge looks and feels satisfying with 1–4 players and stays smooth on mobile |
| M2 | Job loop | Tank, battery, van dumping, cleanliness %, earnings that save, on Meadow Farm |
| M3 | Lobby and refinery | Hub with shop, upgrades and refinery processing between jobs |
| M4 | Parties | Lobby map select, party size 1–4, invites, teleport to a private job server and back |
| M5 | More maps | Old Town and Quarry, with scraper, filter and drill |
| M6 | Launch | Co-op spills, events, Harbor and The Plant, tutorial, monetization, mobile and performance passes |

## Open questions

- **Does map cleanliness persist between runs?** Default assumption: each job starts
  fully polluted, and progress toward unlocks is tracked per player. The alternative
  (a party's cleaned map stays cleaned) raises the question of whose save it is.
- Lobby design: party UI, invite flow, whether to offer public matchmaking later.
- Art style (low-poly stylized assumed).
