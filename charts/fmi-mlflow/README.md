
# Helm chart for installing MLflow and CloudNativePG in OpenShift

## Contents

MLflow tracking server with PostgreSQL cluster.

* [MLflow tracking server](https://mlflow.org/docs/latest/self-hosting/architecture/tracking-server/)
* [CloudNativePG](https://cloudnative-pg.io/documentation/1.27/)

## Requirements

Tested with:
 * OpenShift 4.16
 * CloudNativePG 1.27.1 (prod), 1.30.1 (test). Don't upgrade to 1.31+ before migrating backups to the Barman Cloud Plugin, see Backups
 * MLflow 3.17.1

## Preconditions

CloudnativePG operator needs to be installed in the OpenShift cluster before deploying the helm chart. Follow the instructions from [here](https://cloudnative-pg.io/documentation/1.27/getting-started/installation/).

The following secrets need to be created before deploying the helm chart.

* s3-credentials (for storing mlflow artifacts and database backups)
* postgresql-mlflow-secret (postgresql credentials for mlflow database)
* postgresql-superuser-secret (postgresql admin credentials)
* flask-secret (`SECRET_KEY` for the CSRF protection of the basic-auth app, the server refuses to start without it)
* mlflow-admin-credentials (optional, `password` of the mlflow admin user; only needed on the first start against an empty users database)

```
oc create secret generic s3-credentials --from-env-file=env/s3-credentials
oc create secret generic postgresql-mlflow-secret --from-env-file=env/postgresql-mlflow-secret
oc create secret generic postgresql-superuser-secret --from-env-file=env/postgresql-superuser-secret
oc create secret generic flask-secret --from-literal=SECRET_KEY=$(openssl rand -hex 32)
oc create secret generic mlflow-admin-credentials --from-literal=password=<admin password>
```

The basic-auth configuration (basic-auth.ini) is rendered by the chart into the `mlflow-auth` ConfigMap (templates/auth-config.yaml).
It contains no secrets: the database uris have no credentials, libpq reads them from the `PGUSER` and `PGPASSWORD` environment variables.
Basic-auth options are documented [here](https://mlflow.org/docs/latest/self-hosting/security/basic-http-auth/).

## Installing

After the secrets are in place install the chart with:
```
helm install mlflow . -f values.yaml
```

## Image

The official `ghcr.io/mlflow/mlflow:v<version>-full` image is used as is, it contains the auth, postgresql and s3 dependencies.
By default the tag is derived from `appVersion` in Chart.yaml. Images can be found from [here](https://github.com/mlflow/mlflow/pkgs/container/mlflow).

### values.yaml

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| environment | string | "" | Choose between dev/prod based on where the charts will be installed |
| host | string | "" | Openshift host URI |
| mlflow.replicas | int | 1 | Number of mlflow deployment instances |
| mlflow.image.repository | string | "ghcr.io/mlflow/mlflow" | MLflow image |
| mlflow.image.tag | string | "" | Image tag, defaults to v<appVersion>-full |
| auth.defaultPermission | string | "READ" | Default permission for all resources for users without an explicit grant |
| auth.adminUsername | string | "admin" | Admin user created on the first start |
| auth.adminSecret | string | "mlflow-admin-credentials" | Optional secret with the admin `password` |
| auth.flaskSecret | string | "flask-secret" | Secret with the flask `SECRET_KEY` |
| workspaces.enabled | bool | `false` | Enable workspaces (`--enable-workspaces`). Changes the permission model, see values.yaml |
| workspaces.grantDefaultAccess | bool | `true` | With workspaces enabled, users without a grant get auth.defaultPermission in the "default" workspace |
| route.timeout | string | "5m" | Router timeout, artifacts are proxied through the server |
| recovery.enabled | bool | `false` | Enable if recovering from backup |
| recovery.ondemand | bool | `false` | Enable if recovering from manually created backup |
| recovery.name | string | "" | Name of the manually created backup |
| recovery.serverName | string | "" | Name of the source cluster (postgresql.clusterName) where the backups are read from |
| recovery.backupPath | string | "" | S3 path of the source backups, defaults to objectStorage.s3.backupPath |
| objectStorage.s3.secretName | string | "" | Where the S3 credentials are stored |
| objectStorage.s3.bucketName | string | "mlflow" | Bucketname where everything will be stored |
| objectStorage.s3.endpointUrl | string | "" | Endpoint url for the S3 instance |
| objectStorage.s3.artifactPath | string | "" | Subpath for the artifact store. Don't change it afterwards, existing runs refer to it |
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

Ref. https://mlflow.org/docs/latest/self-hosting/migration

The 3.5.1 → 3.17.1 upgrade has its own runbook: [UPGRADE-3.17.md](UPGRADE-3.17.md).

Read the [changelog](https://github.com/mlflow/mlflow/blob/master/CHANGELOG.md) first. Mixed versions are not supported,
so the server has to be stopped while the databases are migrated. For larger upgrades restore the database into a new cluster
(like in UPGRADE-3.17.md), so that the old cluster stays untouched for a rollback.

1. Stop the server and take a backup (see Backups).
2. Update `appVersion` in Chart.yaml (or `mlflow.image.tag`), set `mlflow.replicas: 0` and upgrade the charts:
```
helm upgrade mlflow -f values.yaml .
```
3. Run the database migrations (both the tracking and the users database):
```
oc delete job mlflow-migrate-job --ignore-not-found
oc process mlflow-migrate | oc apply -f -
oc logs -f job/mlflow-migrate-job
```
4. Set `mlflow.replicas: 1` and upgrade the charts again.

NOTE:
* Always change the replicas through values.yaml, otherwise the next `helm upgrade` reverts an `oc scale`.
* The basic-auth app also migrates the users database automatically when the server starts.
* MLflow tracking server works with the older version of the SDK (client), up to one major version difference (e.g., 2.x to 3.x).
* MLflow tracking server may not work with the newer version of the SDK (client).


## Backups

There are daily backups (at 00:00 UTC) of the database to s3 bucket. Also the WAL is saved, so point in time recovery is also possible. 
By default the latest version will be restored. Backups have 30 days retention.

NOTE: Native (in-tree) Barman Cloud support (spec.backup.barmanObjectStore, spec.externalClusters[].barmanObjectStore) is deprecated. The removal has been postponed twice (1.29 → 1.30 → 1.31), it still works in 1.30.x but will be removed in CloudNativePG 1.31.0. Migrate to the [Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/) before that.

### Recovery

1. Change postgresql.clusterName in the `values.yaml` to a new name, e.g. pg-cluster-v2. 
2. Change revocery.serverName to the current cluster name, e.g. pg-cluster-v1. The serverName is used to identify the backups to restore from.
3. Change mlflow.replicas to 0 to avoid connection issues during recovery. The old cluster is not deleted by helm (`helm.sh/resource-policy: keep`), delete it manually when no longer needed.
4. Start the recovery by upgrading helm charts:
```
helm upgrade mlflow -f values.yaml .
```
5. Change mlflow.replicas back to 1 and upgrade the charts. The basic-auth config follows postgresql.clusterName automatically.
6. Verify that the data is restored correctly.


