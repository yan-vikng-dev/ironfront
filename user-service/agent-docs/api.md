# API v1 (Scaffold)

## POST /auth/exchange
Request:
- `provider`: `"dev" | "pgs"`
- `proof`: string

Response:
- `account_id`
- `session_token`
- `expires_at_unix`
- `is_new_account`

## GET /me
- Requires `Authorization: Bearer <session_token>`.
- Returns authoritative profile payload.
- Time fields use Unix timestamp integers (seconds) with nullable semantics when unset (for example `username_updated_at_unix: number | null`).

## PATCH /me/username
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ username }`
- Marks username onboarding complete by setting `username_updated_at_unix`.

## PATCH /me/loadout
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ selected_tank_id?: string, tanks?: Record<string, { unlocked_shell_ids, shell_loadout_by_id }> }` — full loadout replace.
- Server: validate payload (tank_ids must be owned, shells must be unlocked per catalog); overwrite loadout.
- Response: `{ loadout }` or 400 `{ "error": "INVALID_LOADOUT" }`.

## POST /me/unlock-tank
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ tank_id: string }`.
- Server: validate tank in catalog; check not already owned; deduct economy; add tank to loadout. Single transaction.
- Response: `{ economy, loadout }` or 400 `{ "error": "INSUFFICIENT_FUNDS" | "ALREADY_OWNED" | "INVALID_TANK" }`.

## POST /me/unlock-shell
- Requires `Authorization: Bearer <session_token>`.
- Request: `{ tank_id: string, shell_id: string }`.
- Server: validate shell in catalog and valid for tank; check user owns tank; check not already unlocked; deduct economy; add shell to tank loadout. Single transaction.
- Response: `{ economy, loadout }` or 400 `{ "error": "INSUFFICIENT_FUNDS" | "ALREADY_OWNED" | "INVALID_SHELL" | "SHELL_NOT_FOR_TANK" | "TANK_NOT_OWNED" }`.

## POST /play/ticket
- Requires `Authorization: Bearer <session_token>`.
- Response: `{ ticket, expires_at_unix }`. Ticket is a JWT (RS256) for game server join auth.
