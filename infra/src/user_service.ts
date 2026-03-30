import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as config from "./config.ts";
import { enabledApis } from "./services.ts";

const serviceName = `user-service-${config.userServiceStage}`;
const userServiceCustomDomain = "api.ironfront.live";

const runServiceAccount = new gcp.serviceaccount.Account(
  `${serviceName}-sa`,
  {
    project: config.project,
    accountId: `${serviceName}-sa`.slice(0, 30),
    displayName: `Service account for ${serviceName}`
  },
  { dependsOn: enabledApis }
);

new gcp.projects.IAMMember(`${serviceName}-secret-accessor`, {
  project: config.project,
  role: "roles/secretmanager.secretAccessor",
  member: pulumi.interpolate`serviceAccount:${runServiceAccount.email}`
});

new gcp.artifactregistry.RepositoryIamMember(
  `${serviceName}-registry-reader`,
  {
    project: config.project,
    location: config.region,
    repository: "ironfront",
    role: "roles/artifactregistry.reader",
    member: pulumi.interpolate`serviceAccount:${runServiceAccount.email}`
  }
);

const dbSecret = new gcp.secretmanager.Secret(
  `${serviceName}-database-url`,
  {
    project: config.project,
    secretId: `${serviceName}-database-url`,
    replication: { auto: {} }
  },
  { dependsOn: enabledApis }
);
const dbSecretVersion = new gcp.secretmanager.SecretVersion(
  `${serviceName}-database-url-v`,
  { secret: dbSecret.id, secretData: config.databaseUrl }
);

const pgsSecret = new gcp.secretmanager.Secret(
  `${serviceName}-pgs-secret`,
  {
    project: config.project,
    secretId: `${serviceName}-pgs-web-client-secret`,
    replication: { auto: {} }
  },
  { dependsOn: enabledApis }
);
const pgsSecretVersion = new gcp.secretmanager.SecretVersion(
  `${serviceName}-pgs-secret-v`,
  { secret: pgsSecret.id, secretData: config.pgsWebClientSecret }
);

const ticketSecret = new gcp.secretmanager.Secret(
  `${serviceName}-ticket-key`,
  {
    project: config.project,
    secretId: `${serviceName}-ticket-signing-key`,
    replication: { auto: {} }
  },
  { dependsOn: enabledApis }
);
const ticketSecretVersion = new gcp.secretmanager.SecretVersion(
  `${serviceName}-ticket-key-v`,
  { secret: ticketSecret.id, secretData: config.ticketSigningPrivateKey }
);

const image = `${config.region}-docker.pkg.dev/${config.project}/ironfront/user-service:initial`;

const envs: gcp.types.input.cloudrunv2.ServiceTemplateContainerEnv[] = [
  { name: "STAGE", value: config.userServiceStage },
  { name: "SESSION_TTL_SECONDS", value: "86400" },
  {
    name: "DATABASE_URL",
    valueSource: {
      secretKeyRef: { secret: dbSecret.secretId, version: "latest" }
    }
  },
  {
    name: "PGS_WEB_CLIENT_ID",
    value:
      "556532261549-5sfh8fmkgs232240dviunjr3e4kqeh8a.apps.googleusercontent.com"
  },
  {
    name: "PGS_WEB_CLIENT_SECRET",
    valueSource: {
      secretKeyRef: { secret: pgsSecret.secretId, version: "latest" }
    }
  },
  {
    name: "TICKET_SIGNING_PRIVATE_KEY",
    valueSource: {
      secretKeyRef: { secret: ticketSecret.secretId, version: "latest" }
    }
  }
];

const service = new gcp.cloudrunv2.Service(
  serviceName,
  {
    project: config.project,
    location: config.region,
    name: serviceName,
    deletionProtection: false,
    ingress: "INGRESS_TRAFFIC_ALL",
    defaultUriDisabled: true,
    template: {
      serviceAccount: runServiceAccount.email,
      scaling: { minInstanceCount: 0, maxInstanceCount: 2 },
      containers: [{ image, ports: { containerPort: 8080 }, envs }]
    }
  },
  {
    dependsOn: [dbSecretVersion, pgsSecretVersion, ticketSecretVersion],
    ignoreChanges: ["template.containers[0].image"]
  }
);

new gcp.cloudrunv2.ServiceIamMember("user-service-public-invoker", {
  name: service.name,
  location: config.region,
  project: config.project,
  role: "roles/run.invoker",
  member: "allUsers"
});

new gcp.cloudrun.DomainMapping(
  `${serviceName}-domain`,
  {
    project: config.project,
    location: config.region,
    name: userServiceCustomDomain,
    metadata: { namespace: config.project },
    spec: { routeName: serviceName }
  },
  { dependsOn: [service] }
);

export const userServicePublicUrl = `https://${userServiceCustomDomain}`;
