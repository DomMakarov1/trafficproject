# Muck Crew

A co-op cleanup game for Roblox. See [docs/DESIGN.md](docs/DESIGN.md) for the design plan.

The code lives in this repo and is synced into Roblox Studio with [Rojo](https://rojo.space).

## Places

The experience has two places, each with its own Rojo project:

| Place | Project file | What it is |
|---|---|---|
| Lobby | `lobby.project.json` | Hub, refinery, shop, map and party selection. The start place. |
| Job | `job.project.json` | The cleanup map a party plays on. |

Both share the code in `src/shared`.

## One-time setup

1. **Install the tools.** Install [Rokit](https://github.com/rojo-rbx/rokit), then in this folder run:
   ```
   rokit install
   ```
   This installs the exact versions of Rojo, StyLua and Selene pinned in `rokit.toml`.

2. **Install the Rojo plugin into Studio.** Close Studio, then run:
   ```
   rojo plugin install
   ```
   This installs the plugin version that matches the Rojo CLI. Reopen Studio and you'll
   see a **Rojo** button in the **Plugins** tab.

3. **Create the experience.** In Studio, create a new Baseplate and publish it as
   **Muck Crew**. This first place is the **Lobby**. Then add a second place named
   **Job** to the same experience (Creator Dashboard → your experience → Places).

4. **Editor (optional).** Open the folder in VS Code and install the recommended
   extensions when prompted (Rojo, Luau LSP, StyLua, Selene).

## Connecting to Studio

1. In this folder, start the Rojo server for the place you're working on:
   ```
   rojo serve job.project.json
   ```
2. Open that place in Studio.
3. **Plugins → Rojo → Connect** (default address `localhost:34872`).
4. Press **Play**. The Output window should show:
   ```
   [Muck Crew] job server started (v0.0.1)
   [Muck Crew] job client started (v0.0.1)
   ```

To work on both places at once, serve the lobby on a different port and enter that
port in the Rojo plugin when connecting from the Lobby place:
```
rojo serve lobby.project.json --port 34873
```

### How syncing works
- **Code lives in this repo.** Edit scripts here, not in Studio. Rojo overwrites synced
  scripts, so changes made to them in Studio are lost.
- **The world lives in Studio.** Maps, parts and anything else not listed in a project
  file stay in the place and are saved to Roblox as usual. Rojo doesn't touch them.

## Code layout

```
src/
  shared/        ReplicatedStorage.Shared: code used by both places
  lobby/server/  ServerScriptService.Server in the Lobby place
  lobby/client/  StarterPlayerScripts.Client in the Lobby place
  job/server/    ServerScriptService.Server in the Job place
  job/client/    StarterPlayerScripts.Client in the Job place
```

Each server entry script loads every module in its `Services` folder, and each client
entry script loads every module in its `Controllers` folder. A module can export an
`init()` (setup, runs first for all modules) and a `start()` (runs after every
module's `init()`).

## Checks

```
stylua --check src
selene src
```

To format everything: `stylua src`.
