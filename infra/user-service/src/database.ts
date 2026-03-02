import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

type DatabaseArgs = {
  project: string;
  region: string;
  serviceName: string;
  dbInstanceName: string;
  dbUserPassword: pulumi.Input<string>;
  dbDeletionProtection: boolean;
  dbSecretName: string;
  dependsOn: gcp.projects.Service[];
};

export function createDatabaseResources(args: DatabaseArgs) {
  const databaseInstance = new gcp.sql.DatabaseInstance(
    args.dbInstanceName,
    {
      project: args.project,
      region: args.region,
      name: args.dbInstanceName,
      databaseVersion: "POSTGRES_18",
      deletionProtection: args.dbDeletionProtection,
      settings: {
        edition: "ENTERPRISE",
        tier: "db-custom-1-3840",
        availabilityType: "ZONAL",
        diskType: "PD_SSD",
        diskSize: 20,
        backupConfiguration: {
          enabled: true,
          pointInTimeRecoveryEnabled: true
        }
      }
    },
    { dependsOn: args.dependsOn }
  );

  const dbUser = new gcp.sql.User(`${args.dbInstanceName}-user_service_app`, {
    project: args.project,
    instance: databaseInstance.name,
    name: "user_service_app",
    password: args.dbUserPassword
  });

  new gcp.sql.Database(`${args.dbInstanceName}-user_service`, {
    project: args.project,
    name: "user_service",
    instance: databaseInstance.name
  }, { dependsOn: [dbUser] });

  const databaseUrlSecret = new gcp.secretmanager.Secret(
    args.dbSecretName,
    {
      project: args.project,
      secretId: args.dbSecretName,
      replication: {
        auto: {}
      }
    },
    { dependsOn: args.dependsOn }
  );

  const databaseUrl = pulumi
    .all([databaseInstance.connectionName, args.dbUserPassword])
    .apply(([connectionName, password]) => {
      const encodedPassword = encodeURIComponent(password);
      return `postgresql://user_service_app:${encodedPassword}@/user_service?host=/cloudsql/${connectionName}`;
    });

  const databaseUrlSecretVersion = new gcp.secretmanager.SecretVersion(
    `${args.dbSecretName}-current`,
    {
      secret: databaseUrlSecret.id,
      secretData: databaseUrl
    }
  );

  return {
    databaseInstance,
    databaseUrlSecret,
    databaseUrlSecretVersion
  };
}
