import * as pulumi from "@pulumi/pulumi";

const cfg = new pulumi.Config();
const gcpCfg = new pulumi.Config("gcp");

export const project = gcpCfg.require("project");
export const region = gcpCfg.require("region");
export const userServiceStage = cfg.require("userServiceStage");
export const userServiceImageTag = cfg.require("userServiceImageTag");

export const databaseUrl = cfg.requireSecret("databaseUrl");
export const pgsWebClientSecret = cfg.requireSecret("pgsWebClientSecret");
export const ticketSigningPrivateKey = cfg.requireSecret("ticketSigningPrivateKey");
