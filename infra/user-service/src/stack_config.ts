import * as pulumi from "@pulumi/pulumi";

const gcpCfg = new pulumi.Config("gcp");
const stackCfg = new pulumi.Config();

export const project = gcpCfg.require("project");
export const region = gcpCfg.require("region");

export const stage = stackCfg.require("stage");
export const serviceName = `user-service-${stage}`;
export const imageTag = stackCfg.require("imageTag");
export const minInstanceCount = stackCfg.requireNumber("minInstanceCount");
export const maxInstanceCount = stackCfg.requireNumber("maxInstanceCount");
export const enableCustomDomain = stackCfg.requireBoolean("enableCustomDomain");
export const customDomain = stackCfg.require("customDomain");
export const dbInstanceName = stackCfg.require("dbInstanceName");
export const dbUserPassword = stackCfg.requireSecret("dbUserPassword");
export const dbDeletionProtection = stackCfg.requireBoolean("dbDeletionProtection");
export const cloudRunDeletionProtection = stackCfg.requireBoolean("cloudRunDeletionProtection");
export const dbSecretName = stackCfg.require("dbSecretName");
export const pgsWebClientSecret = stackCfg.requireSecret("pgsWebClientSecret");
export const pgsWebClientSecretName = stackCfg.require("pgsWebClientSecretName");
export const ticketSigningPrivateKey = stackCfg.requireSecret("ticketSigningPrivateKey");
export const ticketSigningSecretName = stackCfg.require("ticketSigningSecretName");
