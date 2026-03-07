import * as gcp from "@pulumi/gcp";

type CloudRunArgs = {
  project: string;
  region: string;
  serviceName: string;
  deletionProtection: boolean;
  imageTag: string;
  stage: string;
  minInstanceCount: number;
  maxInstanceCount: number;
  serviceAccountEmail: gcp.serviceaccount.Account["email"];
  databaseUrlSecretId: gcp.secretmanager.Secret["secretId"];
  pgsWebClientSecretId: gcp.secretmanager.Secret["secretId"];
  ticketSigningPrivateKeyId: gcp.secretmanager.Secret["secretId"];
  dependsOn: gcp.secretmanager.SecretVersion[];
};

export function createCloudRunService(args: CloudRunArgs) {
  const image = `${args.region}-docker.pkg.dev/${args.project}/ironfront/user-service:${args.imageTag}`;
  const envs: gcp.types.input.cloudrunv2.ServiceTemplateContainerEnv[] = [
    { name: "STAGE", value: args.stage },
    { name: "SESSION_TTL_SECONDS", value: "86400" },
    {
      name: "DATABASE_URL",
      valueSource: {
        secretKeyRef: {
          secret: args.databaseUrlSecretId,
          version: "latest"
        }
      }
    }
  ];
  envs.push({
    name: "PGS_WEB_CLIENT_ID",
    value: "556532261549-5sfh8fmkgs232240dviunjr3e4kqeh8a.apps.googleusercontent.com"
  });
  envs.push({
    name: "PGS_WEB_CLIENT_SECRET",
    valueSource: {
      secretKeyRef: {
        secret: args.pgsWebClientSecretId,
        version: "latest"
      }
    }
  });
  envs.push({
    name: "TICKET_SIGNING_PRIVATE_KEY",
    valueSource: {
      secretKeyRef: {
        secret: args.ticketSigningPrivateKeyId,
        version: "latest"
      }
    }
  });

  const service = new gcp.cloudrunv2.Service(
    args.serviceName,
    {
      project: args.project,
      location: args.region,
      name: args.serviceName,
      deletionProtection: args.deletionProtection,
      ingress: "INGRESS_TRAFFIC_ALL",
      template: {
        serviceAccount: args.serviceAccountEmail,
        scaling: {
          minInstanceCount: args.minInstanceCount,
          maxInstanceCount: args.maxInstanceCount
        },
        containers: [
          {
            image,
            ports: { containerPort: 8080 },
            envs
          }
        ]
      }
    },
    { dependsOn: args.dependsOn }
  );

  new gcp.cloudrunv2.ServiceIamMember("public-invoker", {
    name: service.name,
    location: args.region,
    project: args.project,
    role: "roles/run.invoker",
    member: "allUsers"
  });

  return { service, image };
}
