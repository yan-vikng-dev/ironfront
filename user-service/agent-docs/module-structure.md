# Module Structure

- `src/server.ts`: HTTP server bootstrap.
- `src/api/`: HTTP route handlers; path-based structure mirrors game client (`auth/exchange/POST`, `me/GET`, `me/username/PATCH`). Middleware lives at api root (`require_bearer_session.ts`).
- `src/auth/`: session/auth primitives.
- Persistence is Postgres-first via Drizzle and Cloud SQL.

## Justfile (from user-service/)
- `fix`: lint/typecheck
- `dev`: run user-service locally; loads `.env.dev` (STAGE=dev, DATABASE_URL, etc.)
- `push-image`: build and push Docker image to Artifact Registry
- `migrate dev`: run `drizzle push` against local Postgres (`.env.dev`)
- `migrate prod`: run `drizzle push` against prod DB (`.env.prod` DATABASE_URL)
- `deploy`: push-image, set imageTag in Pulumi prod stack, pulumi up
