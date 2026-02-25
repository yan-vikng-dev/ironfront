# Server Write Plan

## Overview

Persist account mutations (loadout, economy) via user-service. Use dedicated purchase routes for cross-domain atomic actions (unlock + deduct). Use PATCH /me/loadout for loadout-only mutations (selected tank, ammo counts).

## Decisions

- **Hybrid routes** — Dedicated endpoints for purchases (atomic economy + loadout). PATCH /me/loadout for simple loadout mutations.
- **Dedicated purchase routes** — `POST /me/unlock-tank`, `POST /me/unlock-shell` (separate, not a generic purchase route).
- **PATCH /me/loadout** — Full replace. Client sends full loadout. Server overwrites.
- **Optimistic client** — Client updates local state first, syncs in background. Rollback or refetch on failure.
- **Loadout sync timing** — Immediate for selected-tank change; debounced (~500ms) for ammo counts.

## Routes

### POST /me/unlock-tank
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ tank_id: string }`.
- Server: validate tank exists and cost; deduct economy; add tank to loadout. Single transaction.
- Response: updated `{ economy, loadout }` or error (INSUFFICIENT_FUNDS, ALREADY_OWNED, INVALID_TANK).

### POST /me/unlock-shell
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ tank_id: string, shell_id: string }`.
- Server: validate shell exists for tank and cost; deduct economy; add shell to tank loadout. Single transaction.
- Response: updated `{ economy, loadout }` or error (INSUFFICIENT_FUNDS, ALREADY_OWNED, INVALID_SHELL, SHELL_NOT_FOR_TANK).

### PATCH /me/loadout
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ selected_tank_id?: string, tanks?: Record<string, { unlocked_shell_ids, shell_loadout_by_id }> }` — full loadout replace.
- Server: validate payload (tank_ids must be owned, shells must be unlocked); overwrite loadout.
- Response: `{ loadout }` or error (INVALID_LOADOUT).

## Flow

1. **Garage tank unlock** — Client calls `POST /me/unlock-tank`. On success: update local Account. On failure: rollback local, show error.
2. **Garage shell unlock** — Client calls `POST /me/unlock-shell`. Same pattern.
3. **Garage selected tank / ammo edit** — Client mutates local Account, calls `PATCH /me/loadout` (immediate for selection, debounced for ammo).
4. **Match rewards** — Deferred. Economy persistence when match-end verification exists, or PATCH /me/economy if we trust client for now.

## Open Questions

### Source of truth for catalog (tanks, shells, costs)
- **Current state**: TankSpec and ShellSpec in game (Godot resources), with `dollar_cost` and `unlock_cost`. User-service has no catalog.
- **Options**:
  - **User-service catalog**: Table or config in user-service. Single source of truth. Game must stay in sync or fetch catalog. Duplication risk.
  - **Shared config / package**: Shared TypeScript/JSON consumed by both game (via codegen or import) and user-service. One definition, two runtimes.
  - **Game as source, user-service mirrors**: Export from game build step (e.g. JSON) → user-service ingests. Game stays canonical; user-service is a derived copy.
  - **User-service as source, game fetches**: API returns catalog. Game fetches at startup. User-service is canonical. Game depends on network for config.
- **Trade-off**: Who owns game balance data? Game needs it for UI, validation, gameplay. User-service needs it for purchase validation. Duplication is inevitable unless we have a clear primary and sync strategy.

### PATCH /me/loadout — merge vs full replace
- **Decided**: Full replace. Client sends full loadout state.

### Match rewards persistence
- Persist now (trust client, PATCH /me/economy or include in PATCH /me) vs defer until server-signed match results.
