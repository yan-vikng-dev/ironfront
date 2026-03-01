# Server Write Plan

## Overview

Persist account mutations (loadout, economy) via user-service. Use dedicated purchase routes for cross-domain atomic actions (unlock + deduct). Use PATCH /me/loadout for loadout-only mutations (selected tank, ammo counts).

## Decisions

- **Hybrid routes** — Dedicated endpoints for purchases (atomic economy + loadout). PATCH /me/loadout for simple loadout mutations.
- **Dedicated purchase routes** — `POST /me/unlock-tank`, `POST /me/unlock-shell` (separate, not a generic purchase route).
- **PATCH /me/loadout** — Full replace. Client sends full loadout. Server overwrites.
- **Optimistic client** — Client updates local state first, syncs in background. Rollback or refetch on failure.
- **Loadout sync timing** — Immediate for selected-tank change; debounced (~500ms) for ammo counts.
- **Catalog source of truth** — Game as source. Export from game build → user-service loads catalog.json. Implemented via `just build` (game/tools/export_catalog, user-service/catalog).
- **Match rewards** — Deferred until server-signed match results exist.
- **CI/CD catalog** — Deferred. Local `just build` produces catalog; pipeline integration TBD.
- **Error format** — Simple string in body: `{ "error": "INSUFFICIENT_FUNDS" }` with appropriate HTTP status (400 for client errors).
- **Starter tank** — No special handling. Server validates ALREADY_OWNED if player tries to unlock a tank they already own.

## Routes

### POST /me/unlock-tank
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ tank_id: string }`.
- Server: validate tank in catalog; check not already owned; deduct economy; add tank to loadout. Single transaction.
- Response: `{ economy, loadout }` or 400 `{ "error": "INSUFFICIENT_FUNDS" | "ALREADY_OWNED" | "INVALID_TANK" }`.

### POST /me/unlock-shell
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ tank_id: string, shell_id: string }`.
- Server: validate shell in catalog and valid for tank; check user owns tank; check not already unlocked; deduct economy; add shell to tank loadout. Single transaction.
- Response: `{ economy, loadout }` or 400 `{ "error": "INSUFFICIENT_FUNDS" | "ALREADY_OWNED" | "INVALID_SHELL" | "SHELL_NOT_FOR_TANK" | "TANK_NOT_OWNED" }`.

### PATCH /me/loadout
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ selected_tank_id?: string, tanks?: Record<string, { unlocked_shell_ids, shell_loadout_by_id }> }` — full loadout replace.
- Server: validate payload (tank_ids must be owned, shells must be unlocked per catalog); overwrite loadout.
- Response: `{ loadout }` or 400 `{ "error": "INVALID_LOADOUT" }`.

## Flow

1. **Garage tank unlock** — Client calls `POST /me/unlock-tank`. On success: update local Account. On failure: rollback local, show error string.
2. **Garage shell unlock** — Client calls `POST /me/unlock-shell`. Same pattern.
3. **Garage selected tank / ammo edit** — Client mutates local Account, calls `PATCH /me/loadout` (immediate for selection, debounced for ammo).
4. **Match rewards** — Deferred. No economy persistence from match end until game-server verification exists.

## Phased Implementation

**Phase 1: User-service routes**
- Load catalog via `loadCatalog()` (catalog.json in user-service/catalog from `just build`).
- `PATCH /me/loadout`: validate loadout shape; ensure tank_ids owned and shells unlocked; overwrite DB. Return updated loadout.
- `POST /me/unlock-tank`: validate tank_id in catalog; if already in loadout.tanks → 400 ALREADY_OWNED; if economy.dollars < cost → 400 INSUFFICIENT_FUNDS; else atomic update economy + loadout.
- `POST /me/unlock-shell`: validate shell_id in catalog, tank_id owned, shell in tank allowed_shell_ids; if already unlocked → 400 ALREADY_OWNED; if economy.dollars < cost → 400 INSUFFICIENT_FUNDS; else atomic update economy + loadout.
- All errors: `{ "error": "CODE" }` with 400.

**Phase 2: Game client — loadout serializer + API client**
- Add serializer: Account.loadout → API payload (selected_tank_id, tanks with unlocked_shell_ids, shell_loadout_by_id as string keys).
- Add `UserServiceClient.update_loadout(loadout_payload)`, `unlock_tank(tank_id)`, `unlock_shell(tank_id, shell_id)`.
- Implement `MeLoadoutPatch`, `UnlockTankPost`, `UnlockShellPost` API request nodes (or equivalent).

**Phase 3: Game client — garage wiring**
- Tank unlock: on `unlock_tank_requested`, optimistic local update, call `unlock_tank`. On failure: rollback local, show error.
- Shell unlock: on `shell_unlock_requested`, optimistic local update, call `unlock_shell`. On failure: rollback local, show error.
- Selected tank change: after local update, call `update_loadout` immediately.
- Ammo edit: after local update, call `update_loadout` debounced (~500ms).

**Phase 4: Polish**
- Error message display in garage UI.
- Refetch /me on auth refresh if loadout may have changed elsewhere (optional, low priority).
