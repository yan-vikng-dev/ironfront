# Task: Convert Arena Server to Match Server

## Goal

Replace the current infinite-loop arena server with a match-based lifecycle that has a clear start, fill, run, and end. This is required for Agones fleet integration — each GameServer pod runs one match, then shuts down and is replaced by the fleet.

## Current State

- `ServerApp` starts, listens on a fixed port, accepts players indefinitely.
- Players connect via ENet, send a JWT play ticket, and join the arena.
- The arena runs forever — players join and leave freely, no win/end condition.
- Client connects to a hardcoded host (`ironfront.vikng.dev:47111`).

## Target State

### Match lifecycle (server side)

```
BOOT → READY → ALLOCATED → FILLING → ACTIVE → ENDED → SHUTDOWN
```

- **BOOT**: Server starts, loads level, initializes systems.
- **READY**: Server calls Agones SDK `Ready()`. It is now in the warm pool, waiting for allocation.
- **ALLOCATED**: Matchmaker allocated this server. Server receives its allocation ID (from Agones labels or env).
- **FILLING**: Players connect and present JWTs. Server verifies each JWT's `allocation_id` matches its own. A fill timer and/or player count threshold gates the transition to ACTIVE.
- **ACTIVE**: Match is running. New joins may be rejected or allowed (configurable). Match timer counts down.
- **ENDED**: Match timer expires or win condition met. Broadcast results to all peers. Disconnect all peers after a brief delay.
- **SHUTDOWN**: Server calls Agones SDK `Shutdown()`. Pod terminates. Fleet replaces it.

### Agones SDK integration (server side)

The Agones sidecar exposes a REST API on `localhost:${AGONES_SDK_HTTP_PORT}`. The server needs:

- `POST /ready` — call once after boot, when the server can accept players.
- `POST /health` — call on a timer (every 5–10s) to prove liveness.
- `POST /shutdown` — call when match ends and all peers are disconnected.
- `POST /allocate` — NOT called by the server; the matchmaker triggers allocation via the K8s Allocation API.

These are simple HTTP POSTs with no body from GDScript's `HTTPRequest` node.

### Ticket changes

- `server_allocation_id` in the JWT (currently `null`) becomes a real allocation ID.
- Server must verify `claims.allocation_id == my_allocation_id` on every join request.
- First valid join sets `my_allocation_id` if not already set from Agones metadata.

### Client changes

- `ArenaClient` no longer connects to a hardcoded host.
- Client calls matchmaker endpoints (`POST /play/find-match`, poll `GET /play/match-status`).
- Match-status response provides `{ host, port, match_token }`.
- Client uses returned `host:port` for ENet connect and `match_token` for join RPC.
- Post-match: client receives results, returns to menu. Can re-queue.

## Key Decisions to Make

1. **Match duration**: Fixed timer (e.g. 5 minutes)? Score-based? Configurable per mode?
2. **Fill policy**: Minimum players to start? Start timer after first join? Allow late joins during ACTIVE?
3. **Bot backfill**: Keep current bot system? Bots fill remaining slots? Bots only in FILLING phase?
4. **Results payload**: What stats to send at match end (kills, damage, survival time)?
5. **Reconnect**: Allow a disconnected player to rejoin the same match within a window?

## Files to Modify

| File | Change |
|------|--------|
| `game/src/server/server_app.gd` | Add match lifecycle state machine, Agones SDK calls, allocation ID check |
| `game/src/server/arena/arena_session_state.gd` | Add match phase tracking, fill/active/ended transitions |
| `game/src/server/net/server_session_api.gd` | Add match-end broadcast RPC |
| `game/src/client/arena/arena_client.gd` | Replace hardcoded connect with matchmaker-driven flow |
| `game/src/client/net/client_session_api.gd` | Add match-end result handler |
| `user-service/src/api/play/ticket/POST.ts` | Include real `server_allocation_id` in JWT |
| `user-service/src/api/play/` | New matchmaker endpoints (find-match, match-status) |
| `user-service/src/db/schema.ts` | New match_tickets table |
