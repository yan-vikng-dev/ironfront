import * as gcp from "@pulumi/gcp";
import * as pulumi from "@pulumi/pulumi";

type ProjectInfraArgs = {
  project: string;
  region: string;
  dependsOn: gcp.projects.Service[];
};

export function createProjectInfra(args: ProjectInfraArgs) {
  const projectInfo = gcp.organizations.getProjectOutput({
    projectId: args.project
  });
  const projectNumber = projectInfo.number;

  const network = new gcp.compute.Network(
    "ironfront-vpc",
    {
      name: "ironfront-vpc",
      project: args.project,
      autoCreateSubnetworks: false,
      routingMode: "REGIONAL"
    },
    { dependsOn: args.dependsOn }
  );

  const subnet = new gcp.compute.Subnetwork(
    "ironfront-subnet",
    {
      name: "ironfront-subnet",
      project: args.project,
      region: args.region,
      network: network.id,
      ipCidrRange: "10.20.0.0/20",
      privateIpGoogleAccess: true
    },
    { dependsOn: [network] }
  );

  const artifactRepo = new gcp.artifactregistry.Repository(
    "ironfront-registry",
    {
      project: args.project,
      location: args.region,
      repositoryId: "ironfront",
      description: "Ironfront container images",
      format: "DOCKER"
    },
    { dependsOn: args.dependsOn }
  );

  const ciServiceAccount = new gcp.serviceaccount.Account(
    "ironfront-ci-sa",
    {
      project: args.project,
      accountId: "ironfront-ci",
      displayName: "Ironfront CI"
    },
    { dependsOn: args.dependsOn }
  );

  new gcp.artifactregistry.RepositoryIamMember("registry-ci-writer", {
    project: args.project,
    location: args.region,
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
      project: args.project,
      location: args.region,
      repository: artifactRepo.repositoryId,
      role: "roles/artifactregistry.reader",
      member
    });
  });

  const cloudBuildBucket = `${args.project}_cloudbuild`;
  new gcp.storage.BucketIAMMember("cloudbuild-source-admin", {
    bucket: cloudBuildBucket,
    role: "roles/storage.objectAdmin",
    member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
  });
  new gcp.projects.IAMMember("cloudbuild-log-writer", {
    project: args.project,
    role: "roles/logging.logWriter",
    member: pulumi.interpolate`serviceAccount:${ciServiceAccount.email}`
  });

  return {
    networkId: network.id,
    subnetId: subnet.id,
    artifactRepoId: artifactRepo.id,
    ciServiceAccountEmail: ciServiceAccount.email
  };
}
