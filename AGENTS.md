# Ironfront — Agent Entry Point

All project rules live in `.cursor/rules/`. Read the relevant rule before working in a module.

| Rule file | When to read |
|-----------|-------------|
| `ironfront-core.mdc` | Always (auto-applied). Project philosophy, terminology, tooling. |
| `game-code-patterns.mdc` | Editing `game/**/*.gd` — GDScript style, typing, API client, Result pattern. |
| `game-architecture.mdc` | Editing `game/**` — scene lifecycle, runtime structure, refactor rules. |
| `user-service.mdc` | Editing `user-service/**/*.ts` — server rules, API contracts, dev workflow. |
| `infra.mdc` | Editing `infra/**` — Pulumi stacks, config/secret policy. |
| `fleet.mdc` | Editing `fleet/**` — Agones fleet, K8s manifests. |
