import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

type UserServiceArgs = {
  project: string;
  region: string;
  stage: string;
  imageTag: string;
  databaseUrl: pulumi.Output<string>;
  pgsWebClientSecret: pulumi.Output<string>;
  ticketSigningPrivateKey: pulumi.Output<string>;
  dependsOn: gcp.projects.Service[];
};

export function createUserService(args: UserServiceArgs) {
  const serviceName = `user-service-${args.stage}`;

  const runServiceAccount = new gcp.serviceaccount.Account(
    `${serviceName}-sa`,
    {
      project: args.project,
      accountId: `${serviceName}-sa`.slice(0, 30),
      displayName: `Service account for ${serviceName}`
    },
    { dependsOn: args.dependsOn }
  );

  new gcp.projects.IAMMember(`${serviceName}-secret-accessor`, {
    project: args.project,
    role: "roles/secretmanager.secretAccessor",
    member: pulumi.interpolate`serviceAccount:${runServiceAccount.email}`
  });

  new gcp.artifactregistry.RepositoryIamMember(
    `${serviceName}-registry-reader`,
    {
      project: args.project,
      location: args.region,
      repository: "ironfront",
      role: "roles/artifactregistry.reader",
      member: pulumi.interpolate`serviceAccount:${runServiceAccount.email}`
    }
  );

  const dbSecret = new gcp.secretmanager.Secret(
    `${serviceName}-database-url`,
    {
      project: args.project,
      secretId: `${serviceName}-database-url`,
      replication: { auto: {} }
    },
    { dependsOn: args.dependsOn }
  );
  const dbSecretVersion = new gcp.secretmanager.SecretVersion(
    `${serviceName}-database-url-v`,
    { secret: dbSecret.id, secretData: args.databaseUrl }
  );

  const pgsSecret = new gcp.secretmanager.Secret(
    `${serviceName}-pgs-secret`,
    {
      project: args.project,
      secretId: `${serviceName}-pgs-web-client-secret`,
      replication: { auto: {} }
    },
    { dependsOn: args.dependsOn }
  );
  const pgsSecretVersion = new gcp.secretmanager.SecretVersion(
    `${serviceName}-pgs-secret-v`,
    { secret: pgsSecret.id, secretData: args.pgsWebClientSecret }
  );

  const ticketSecret = new gcp.secretmanager.Secret(
    `${serviceName}-ticket-key`,
    {
      project: args.project,
      secretId: `${serviceName}-ticket-signing-key`,
      replication: { auto: {} }
    },
    { dependsOn: args.dependsOn }
  );
  const ticketSecretVersion = new gcp.secretmanager.SecretVersion(
    `${serviceName}-ticket-key-v`,
    { secret: ticketSecret.id, secretData: args.ticketSigningPrivateKey }
  );

  const image = `${args.region}-docker.pkg.dev/${args.project}/ironfront/user-service:${args.imageTag}`;

  const envs: gcp.types.input.cloudrunv2.ServiceTemplateContainerEnv[] = [
    { name: "STAGE", value: args.stage },
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
      project: args.project,
      location: args.region,
      name: serviceName,
      deletionProtection: false,
      ingress: "INGRESS_TRAFFIC_ALL",
      template: {
        serviceAccount: runServiceAccount.email,
        scaling: { minInstanceCount: 0, maxInstanceCount: 2 },
        containers: [{ image, ports: { containerPort: 8080 }, envs }]
      }
    },
    {
      dependsOn: [dbSecretVersion, pgsSecretVersion, ticketSecretVersion]
    }
  );

  new gcp.cloudrunv2.ServiceIamMember("user-service-public-invoker", {
    name: service.name,
    location: args.region,
    project: args.project,
    role: "roles/run.invoker",
    member: "allUsers"
  });

  new gcp.cloudrun.DomainMapping(
    `${serviceName}-domain`,
    {
      project: args.project,
      location: args.region,
      name: `api.ironfront.live`,
      metadata: { namespace: args.project },
      spec: { routeName: serviceName }
    },
    { dependsOn: [service] }
  );

  return { serviceUrl: service.uri, image };
}
