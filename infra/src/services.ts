import * as gcp from "@pulumi/gcp";
import * as config from "./config.ts";

const requiredApis = [
  "artifactregistry.googleapis.com",
  "cloudbuild.googleapis.com",
  "compute.googleapis.com",
  "iam.googleapis.com",
  "logging.googleapis.com",
  "run.googleapis.com",
  "secretmanager.googleapis.com",
  "servicenetworking.googleapis.com",
  "sqladmin.googleapis.com",
  "storage.googleapis.com",
  "iamcredentials.googleapis.com"
];

export const enabledApis = requiredApis.map(
  (api) =>
    new gcp.projects.Service(api, {
      project: config.project,
      service: api,
      disableOnDestroy: false
    })
);
