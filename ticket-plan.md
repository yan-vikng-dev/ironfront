# Play Ticket Plan

## Overview

Replace trusted client payload (player_name, loadout) with a signed ticket issued by user-service. Game server verifies signature and trusts ticket payload—no HTTP call to user-service during join. Enables future matchmaker server-binding.

## Decisions

- **Ticket, not session token** — Enables binding to a specific server/allocation. Session token proves identity but not "which server."
- **User-service issues tickets now** — Matchmaker (dedicated or part of user-service) may issue later. Ticket format stays same.
- **Loadout in ticket** — Signed payload. Game server verifies once, extracts claims. No re-fetch, no separate loadout validation.
- **RSA (asymmetric)** — Private key in user-service, public key in game server. JWT (RS256) via `jose`. Godot 4 verifies with native `Crypto.verify` + `CryptoKey`.

## Ticket Claims

`account_id`, `username`, `loadout`, `server_allocation_id` (null/"*" = any server for now), `exp`

## Flow

1. Client: `POST /play/ticket` with `Authorization: Bearer <session_token>`
2. User-service: validate session, build payload, sign, return ticket
3. Client: connect to game server, send ticket in join handshake
4. Game server: verify signature, expiry, server binding; extract claims; proceed or reject

## Phased Implementation

**Phase 1: Keys + user-service**
- Generate RSA keypair. Private key in user-service env; public key in game server env/config.
- `POST /play/ticket` (Bearer required). Fetch profile, build payload, sign hash with RSA, return ticket. TTL ~60–120s.

**Phase 2: Game client**
- Before arena connect: call `POST /play/ticket`, store ticket.
- Send ticket in join handshake (replace or augment `player_name` + `loadout` in join RPC).

**Phase 3: Game server**
- Load public key at startup. On join: verify signature, parse payload, check `exp` and `server_allocation_id`.
- Use `account_id`, `username`, `loadout` from ticket. Reject invalid/missing ticket.

**Phase 4: Cleanup**
- Remove legacy trusted client payload from join RPC. Ticket mandatory.
