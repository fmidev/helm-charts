
# Helm chart for installing MLflow and CloudNativePG in OpenShift

## Contents

MlFlow tracking server with potgresql cluster.

* [MLflow tracking server](https://mlflow.org/docs/latest/self-hosting/architecture/tracking-server/)
* [CloudNativePG](https://cloudnative-pg.io/documentation/1.27/)

## Requirements

Tested with: 
 * OpenShift 4.16
 * CloudNativePG 1.27.1
 * MLflow 3.5.1.

## Preconditions

CloudnativePG operator needs to be installed in the OpenShift cluster before deploying the helm chart. Follow the instructions from [here](https://cloudnative-pg.io/documentation/1.27/getting-started/installation/).

The following secrets needs to be created before deploying the helm chart.

* basi-auth.ini (contains configurations for the mlflow authentication plugin, overrides [defaults](https://github.com/mlflow/mlflow/blob/0a26232b25033a367ffcfb8907069482ac8bc13a/mlflow/server/auth/basic_auth.ini))
* s3 credentials (for storing mlflow artifacts and database backups)

```
oc create secret generic s3-credentials --from-env-file=env/s3-credentials
oc create secret generic mlflow-auth-config --from-file=basic-auth.ini=env/basic-auth.ini
```

## Installing

After the secrets are in place install the chart with:
```
helm create mlflow . -f values.yaml
oc start-build mlflow
oc scale deployment/mlflow --replicas=1
```

## Image

Use the official mlflow image as a base image. Latest images can be found from [here](https://github.com/mlflow/mlflow/pkgs/container/mlflow).

All the necessary dependencies except s3 components and database drivers are baked into the official image. Missing parts are handled by templates/build-config.yaml.

### values.yaml

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| environment | string | "" | Choose between dev/prod based on where the charts will be installed |
| host | string | "" | Openshift host URI |
| mlflow.replicas | int | 1 | Number of mlflow deployment instances |
| recovery.enabled | bool | `false` | Enable if recovering from backup |
| recovery.ondemand | bool | `false` | Enable if recovering from manually created backup |
| recovery.name | string | "" | Name of the manually created backup |
| recovery.serverName | string | "" | Name of the source cluster (postgresql.clusterName) where the backups are read from |
| objectStorage.s3.secretName | string | "" | Where the S3 credentials are stored |
| objectStorage.s3.bucketName | string | "mlflow" | Bucketname where everything will be stored |
| objectStorage.s3.endpointUrl | string | "" | Endpoint url for the S3 instance |
| objectStorage.s3.artifactPath | string | "" | Subpath for the artifact store |
| objectStorage.s3.backupPath | string | "" | Subpath for storing the backups |
| postgresql.imageName | string | "" | Where the postgresql image will be fetched (contains currently the version also!) |
| postgresql.clusterName | string | "pg-cluster" | Name for the cloudnative-pg cluster |
| postgresql.database | string | "app" | MLflow database name |
| postgresql.owner | string | "app" | Username for the MLflow database |
| postgresql.instances | int | 3 | Number of postgresql instances. Default: 1 primary (rw) and 2 replicas (r). |
| postgresql.storageSize | string | "3Gi" | Size of the storage. Note that the actual size used is the multiple of intances |
| postgresql.secrets.admin | string | "" | Postgresql admin credentials |
| postgresql.secrets.mlflow | string | "" | Postgresql credentials for the user defined in postgresql.owner |


### Upgrading mlflow version

Ref. https://mlflow.org/docs/3.5.0/self-hosting/migration

1. Stop the server:
```
oc scale deployment/mlflow --replicas=0
```
2. Upgrade the new mlflow version in values.yaml. New build should trigger automatically after upgrading charts.
```
mlflow:
  image:
    repository: ghcr.io/mlflow/mlflow
    tag: <new-version>

helm upgrade mlflow -f values.yaml .
```

3. If build doesn't trigger automatically, create a new build manually:
```
oc start-build mlflow
```

4. Run database migrations:
```
oc process mlflow-migrate | oc apply -f -
```

NOTE:
No need to update users database while doing migrations, there is only [one version](https://github.com/mlflow/mlflow/tree/2e9f23c8e5f82ade41cc524752fbce66bbb0665b/mlflow/server/auth/db/migrations/versions) from it currently (and trying to make the migration fails).

But if users database has to be updated at some point, you need to modify the default alembic directory path in the [migration script](https://github.com/mlflow/mlflow/blob/fad68cc2848e9c5da4992a3b08010818cf6d365f/mlflow/store/db/utils.py#L218). The alembic directory is by default store/db_migrations while the auth alembic files are stored in server/auth/db/migrations (the mlflow developers will probably take care of this when it becomes relevant).

5. Restart the server.
```
oc rollout restart deployment/mlflow
oc scale deployment/mlflow --replicas=1
```

NOTE: 
* MLflow tracking server works with the older version of the SDK (client), up to one major version difference (e.g., 2.x to 3.x).
* MLflow tracking server may not work with the newer version of the SDK (client).


## Backups

There are daily backups (at 00:00 UTC) of the database to s3 bucket. Also the WAL is saved, so point in time recovery is also possible. 
By default the latest version will be restored. Backups have 30 days retention.

NOTE: Native support for Barman Cloud backups and recovery is deprecated and will be completely removed in CloudNativePG 1.29.0. Found usage in: spec.backup.barmanObjectStore, spec.externalClusters.0.barmanObjectStore. Please migrate existing clusters to the new Barman Cloud Plugin to ensure a smooth transition.

### Recovery

1. Change postgresql.clusterName in the `values.yaml` to a new name, e.g. pg-cluster-v2. 
2. Change revocery.serverName to the current cluster name, e.g. pg-cluster-v1. The serverName is used to identify the backups to restore from.
3. Change mlflow.replicas to 0 to avoid connection issues during recovery.
4. Start the recovery by upgrading helm charts:
```
helm upgrade mlflow -f values.yaml .
```
5. Update basic-auth.ini which contains the database uri for users table. The database host needs to be changed manually to the new cluster name.
```
sed "s/pg-cluster-v1/$(oc get cluster -o name | sed 's|.*/||')/" env/basic-auth.ini
```
6. Delete secret mlflow-auth-config which contains this basic-auth.ini. And recreate it with the updated file.
```
oc delete secret mlflow-auth-config
oc create secret generic mlflow-auth-config --from-file=basic-auth.ini=env/basic-auth.ini
```
7. Scale the mlflow deployment back to 1.
```
oc scale deployment/mlflow --replicas=1
```
8. Verify that the data is restored correctly.


