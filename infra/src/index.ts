import * as config from "./config.ts";
import { enableRequiredApis } from "./services.ts";
import { createProjectInfra } from "./project.ts";
import { createUserService } from "./user_service.ts";

const enabledApis = enableRequiredApis(config.project);

const projectInfra = createProjectInfra({
  project: config.project,
  region: config.region,
  dependsOn: enabledApis
});

const userService = createUserService({
  project: config.project,
  region: config.region,
  stage: config.userServiceStage,
  imageTag: config.userServiceImageTag,
  databaseUrl: config.databaseUrl,
  pgsWebClientSecret: config.pgsWebClientSecret,
  ticketSigningPrivateKey: config.ticketSigningPrivateKey,
  dependsOn: enabledApis
});

export const vpcId = projectInfra.networkId;
export const subnetId = projectInfra.subnetId;
export const artifactRepoId = projectInfra.artifactRepoId;
export const ciServiceAccountEmail = projectInfra.ciServiceAccountEmail;
export const userServiceUrl = userService.serviceUrl;
export const userServiceDeployedImage = userService.image;
