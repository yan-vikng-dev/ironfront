import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import { createCloudRunService } from "./cloud_run.ts";
import { createCustomDomainLoadBalancer } from "./custom_domain.ts";
import { createDatabaseResources } from "./database.ts";
import { createRuntimeIdentity, grantRuntimeIam } from "./runtime_identity.ts";
import { enableProjectServices } from "./services.ts";
import {
  cloudRunDeletionProtection,
  customDomain,
  dbDeletionProtection,
  dbInstanceName,
  dbSecretName,
  dbUserPassword,
  pgsWebClientSecret,
  pgsWebClientSecretName,
  ticketSigningPrivateKey,
  ticketSigningSecretName,
  enableCustomDomain,
  imageTag,
  maxInstanceCount,
  minInstanceCount,
  project,
  region,
  serviceName,
  stage
} from "./stack_config.ts";

const enabledServices = enableProjectServices(project);

const { runServiceAccount } = createRuntimeIdentity({
  project,
  serviceName,
  dependsOn: enabledServices
});

grantRuntimeIam(project, serviceName, runServiceAccount.email);

const { databaseInstance, databaseUrlSecret, databaseUrlSecretVersion } = createDatabaseResources({
  project,
  region,
  serviceName,
  dbInstanceName,
  dbUserPassword,
  dbDeletionProtection,
  dbSecretName,
  dependsOn: enabledServices
});

const pgsSecret = new gcp.secretmanager.Secret(
  pgsWebClientSecretName,
  {
    project,
    secretId: pgsWebClientSecretName,
    replication: { auto: {} }
  },
  { dependsOn: enabledServices }
);
const pgsWebClientSecretVersion = new gcp.secretmanager.SecretVersion(
  `${pgsWebClientSecretName}-current`,
  {
    secret: pgsSecret.id,
    secretData: pgsWebClientSecret
  }
);

const ticketSigningSecret = new gcp.secretmanager.Secret(
  ticketSigningSecretName,
  {
    project,
    secretId: ticketSigningSecretName,
    replication: { auto: {} }
  },
  { dependsOn: enabledServices }
);
const ticketSigningSecretVersion = new gcp.secretmanager.SecretVersion(
  `${ticketSigningSecretName}-current`,
  {
    secret: ticketSigningSecret.id,
    secretData: ticketSigningPrivateKey
  }
);

const { service, image } = createCloudRunService({
  project,
  region,
  serviceName,
  deletionProtection: cloudRunDeletionProtection,
  imageTag,
  stage,
  minInstanceCount,
  maxInstanceCount,
  serviceAccountEmail: runServiceAccount.email,
  databaseConnectionName: databaseInstance.connectionName,
  databaseUrlSecretId: databaseUrlSecret.secretId,
  pgsWebClientSecretId: pgsSecret.secretId,
  ticketSigningPrivateKeyId: ticketSigningSecret.secretId,
  dependsOn: [
    databaseUrlSecretVersion,
    pgsWebClientSecretVersion,
    ticketSigningSecretVersion
  ]
});

let customDomainIpAddress: pulumi.Output<string> | undefined;
if (enableCustomDomain) {
  customDomainIpAddress = createCustomDomainLoadBalancer({
    project,
    region,
    serviceName,
    customDomain,
    service
  });
}

export const serviceUrl = service.uri;
export const serviceAccountEmail = runServiceAccount.email;
export const deployedImage = image;
export const customDomainDnsARecord = customDomainIpAddress;
export const cloudSqlInstanceConnectionName = databaseInstance.connectionName;
export const databaseUrlSecretId = databaseUrlSecret.secretId;
export const pgsWebClientSecretResourceId = pgsSecret.secretId;
export const ticketSigningPrivateKeyResourceId = ticketSigningSecret.secretId;
