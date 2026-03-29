import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";
import * as config from "./config.ts";
import { enabledApis } from "./services.ts";

const projectInfo = gcp.organizations.getProjectOutput({
  projectId: config.project
});
const projectNumber = projectInfo.number;

const network = new gcp.compute.Network(
  "ironfront-vpc",
  {
    name: "ironfront-vpc",
    project: config.project,
    autoCreateSubnetworks: false,
    routingMode: "REGIONAL"
  },
  { dependsOn: enabledApis }
);

const subnet = new gcp.compute.Subnetwork(
  "ironfront-subnet",
  {
    name: "ironfront-subnet",
    project: config.project,
    region: config.region,
    network: network.id,
    ipCidrRange: "10.20.0.0/20",
    privateIpGoogleAccess: true
  },
  { dependsOn: [network] }
);

const artifactRepo = new gcp.artifactregistry.Repository(
  "ironfront-registry",
  {
    project: config.project,
    location: config.region,
    repositoryId: "ironfront",
    description: "Ironfront container images",
    format: "DOCKER"
  },
  { dependsOn: enabledApis }
);

const ciServiceAccount = new gcp.serviceaccount.Account(
  "ironfront-ci-sa",
  {
    project: config.project,
    accountId: "ironfront-ci",
    displayName: "Ironfront CI"
  },
  { dependsOn: enabledApis }
);

new gcp.artifactregistry.RepositoryIamMember("registry-ci-writer", {
  project: config.project,
  location: config.region,
  repository: artifactRepo.repositoryId,
  role: "roles/artifactregistry.writer",
  member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
});

const defaultReaderMembers = [
  pulumi.interpolate`serviceAccount:${projectNumber}-compute@developer.gserviceaccount.com`,
  pulumi.interpolate`serviceAccount:service-${projectNumber}@serverless-robot-prod.iam.gserviceaccount.com`
];
defaultReaderMembers.forEach((member, i) => {
  new gcp.artifactregistry.RepositoryIamMember(`registry-reader-${i}`, {
    project: config.project,
    location: config.region,
    repository: artifactRepo.repositoryId,
    role: "roles/artifactregistry.reader",
    member
  });
});

const cloudBuildBucket = `${config.project}_cloudbuild`;
new gcp.storage.BucketIAMMember("cloudbuild-source-admin", {
  bucket: cloudBuildBucket,
  role: "roles/storage.objectAdmin",
  member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
});
new gcp.projects.IAMMember("cloudbuild-log-writer", {
  project: config.project,
  role: "roles/logging.logWriter",
  member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
});

const ghWifPool = new gcp.iam.WorkloadIdentityPool(
  "github-wif-pool",
  {
    project: config.project,
    workloadIdentityPoolId: "github-actions",
    displayName: "GitHub Actions"
  },
  { dependsOn: enabledApis }
);

const ghWifProvider = new gcp.iam.WorkloadIdentityPoolProvider(
  "github-wif-provider",
  {
    project: config.project,
    workloadIdentityPoolId: ghWifPool.workloadIdentityPoolId,
    workloadIdentityPoolProviderId: "github-oidc",
    displayName: "GitHub OIDC",
    attributeMapping: {
      "google.subject": "assertion.sub",
      "attribute.repository": "assertion.repository"
    },
    attributeCondition: 'assertion.repository == "yan-vikng-dev/ironfront"',
    oidc: { issuerUri: "https://token.actions.githubusercontent.com" }
  }
);

new gcp.projects.IAMMember("ci-run-admin", {
  project: config.project,
  role: "roles/run.admin",
  member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
});

new gcp.projects.IAMMember("ci-sa-user", {
  project: config.project,
  role: "roles/iam.serviceAccountUser",
  member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
});

new gcp.serviceaccount.IAMMember("ci-sa-github-wif", {
  serviceAccountId: ciServiceAccount.name,
  role: "roles/iam.workloadIdentityUser",
  member: pulumi.interpolate`principalSet://iam.googleapis.com/${ghWifPool.name}/attribute.repository/yan-vikng-dev/ironfront`
});

export const networkId = network.id;
export const subnetId = subnet.id;
export const artifactRepoId = artifactRepo.id;
export const ciServiceAccountEmail = ciServiceAccount.email;
export const ghWifProviderId = ghWifProvider.name;
