# user-service infra

Pulumi stack for deploying `user-service` on Cloud Run. Prod only.

Env: `infra/.env.prod` for prod (db-migrate); `infra/.env.dev` for local dev (just dev).

## Commands
- `pnpm run pulumi:preview`
- `pnpm run pulumi:up`

## Config
- `gcp:project`
- `gcp:region`
- `user-service-infra:imageTag`
- `user-service-infra:stage` (serviceName derived as `user-service-${stage}`)
- `user-service-infra:enableCustomDomain`
- `user-service-infra:customDomain`
- `user-service-infra:minInstanceCount`
- `user-service-infra:maxInstanceCount`
- `user-service-infra:dbInstanceName`
- `user-service-infra:dbUserPassword` (set via `pulumi config set --secret`)
- `user-service-infra:dbDeletionProtection`
- `user-service-infra:cloudRunDeletionProtection`
- `user-service-infra:dbSecretName`
- `user-service-infra:pgsWebClientSecretName`
- `user-service-infra:pgsWebClientSecret` (set via `pulumi config set --secret`)
- `user-service-infra:ticketSigningSecretName`
- `user-service-infra:ticketSigningPrivateKey` (base64-encoded PEM, set via `pulumi config set --secret ticketSigningPrivateKey "$(base64 < ticket_private.pem)"`)

## Database + Secret Flow
- Provisions Cloud SQL Postgres instance/database/user.
- Builds a `DATABASE_URL` secret in Secret Manager using Cloud SQL Unix socket format.
- Grants Cloud Run runtime service account:
  - `roles/cloudsql.client`
  - `roles/secretmanager.secretAccessor`
- Injects `DATABASE_URL` + `SESSION_TTL_SECONDS` into Cloud Run.
- Mounts Cloud SQL socket on `/cloudsql`.

## Custom Domain
When `enableCustomDomain=true`, this stack provisions an HTTPS global load balancer with a managed certificate and exports the IPv4 address to use for an `A` record on the configured domain.
