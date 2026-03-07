## Module Rules
- Keep shared foundation infrastructure in `project-infra/`.
- Keep service deployment resources in their service directory under this module.
- Prefer non-destructive migrations and explicit review for IAM/networking changes.
- Keep non-sensitive config in plain centralized config code, and keep prod secrets in CI/CD-reachable secret stores.

## Config and secret policy
- Keep non-sensitive runtime config centralized in plain config code.
- Use `.env` for local/dev secrets.
- Use CI/CD-reachable secret stores (for example Secret Manager) for prod secrets.

## Env Files
- `user-service/.env.dev`: local development (committed). Used by `just user-service::dev`, `migrate dev`, `studio dev`.
- `user-service/.env.prod`: prod DB URL for migrate/studio (gitignored). Used by `just user-service::migrate prod`, `studio prod`.
