import * as gcp from "@pulumi/gcp";

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
  "storage.googleapis.com"
];

export function enableRequiredApis(project: string) {
  return requiredApis.map(
    (api) =>
      new gcp.projects.Service(api, {
        project,
        service: api,
        disableOnDestroy: false
      })
  );
}
