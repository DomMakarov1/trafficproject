# Muck Crew

A co-op cleanup game for Roblox. See [docs/DESIGN.md](docs/DESIGN.md) for the design plan.

The game is built directly in Roblox Studio. Claude works in Studio through Studio's
built-in MCP server, so the code lives in the places themselves. This repo holds the
design docs.

## Connecting Claude to Studio

The MCP server runs on the same computer as Studio, so Claude has to run there too:
the Claude desktop app, or Claude Code in a terminal.

1. Open Roblox Studio with a place open.
2. Open **Assistant → Manage MCP Servers** and turn on **Enable Studio as MCP server**.
3. Under **Quick connect**, turn on **Claude Code**.
4. Check for the green indicator next to **Enable Studio as MCP server**.

Full details: [Connect to the Roblox Studio MCP server](https://create.roblox.com/docs/studio/mcp).
