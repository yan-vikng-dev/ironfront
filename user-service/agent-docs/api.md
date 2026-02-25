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

## POST /play/ticket
- Requires `Authorization: Bearer <session_token>`.
- Response: `{ ticket, expires_at_unix }`. Ticket is a JWT (RS256) for game server join auth.
