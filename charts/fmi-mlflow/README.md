
# Helm chart for installing MLflow and CloudNativePG in OpenShift

## Contents

MlFlow tracking server with potgresql cluster.

https://mlflow.org/docs/latest/self-hosting/architecture/tracking-server/

## Preconditions

The following secrets needs to be created before deploying the helm chart.

* basi-auth.ini (contains configurations for the authentication plugin)
* s3 credentials

```
oc create secret generic s3-credentials --from-env-file=env/s3-credentials
oc create secret generic mlflow-auth-config --from-file=basic-auth.ini=env/basic-auth.ini
```

## Installing

After the secrets are in place install the chart with:

```
helm create himan . -f values.yaml
oc start-build mlflow
oc scale deployment/mlflow --replicas=1
```

## Image

Use the official mlflow image as a base image. Latest images can be found from [here](https://github.com/mlflow/mlflow/pkgs/container/mlflow).

All the necessary dependencies except s3 components and database drivers are baked into the official image. Missing parts are handled by templates/build-config.yaml.

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
No need to update users database while doing migrations, there is only one version from it currently (and trying to make the migration fails).
https://github.com/mlflow/mlflow/tree/2e9f23c8e5f82ade41cc524752fbce66bbb0665b/mlflow/server/auth/db/migrations/versions

But if you need to update users database at some point, you need to modify the alembic directory path in the migration script as follows:
```
The alembic directory is by default store/db_migrations while the auth alembic files are stored in server/auth/db/migrations.

    final_alembic_dir = (
        os.path.join(_get_package_dir(), "store", "db_migrations")
        if alembic_dir is None
        else alembic_dir
    )

ref. https://github.com/mlflow/mlflow/blob/fad68cc2848e9c5da4992a3b08010818cf6d365f/mlflow/store/db/utils.py#L201
```

5. Restart the server.
```
oc rollout restart deployment/mlflow
oc scale deployment/mlflow --replicas=1
```

NOTE: 
MLflow tracking server works with the older version of the SDK, up to one major version difference (e.g., 2.x to 3.x).
MLflow tracking server may not work with the newer version of the SDK.


## Backups

There are daily backups (at 00:00 UTC) of the database to s3 bucket. Also the WAL is saved, so point in time recovery is also possible. 
By default the latest version will be restored. Backups have 30 days retention.

### Recovery

1. Change postgresql.clusterName in the `values.yaml` to a new name, e.g. pg-cluster-v2. 
2. Change revocery.serverName to the current cluster name, e.g. pg-cluster-v1. The serverName is used to identify the backups to restore from.
3. Change mlflow.replicas to 0 to avoid connection issues during recovery.
4. Update cluster with:
```
helm upgrade mlflow -f values.yaml .
```
5. Update basic-auth.ini which contains the database uri for users table. The database host needs to be changed to the new cluster name.
```
sed "s/pg-cluster-v1/$(oc get cluster -o name | sed 's|.*/||')/" env/basic-auth.ini
```
6. Delete secret mlflow-auth-config which contains this basic-auth.ini. And recreate it with the updated file.
```
oc delete secret mlflow-auth-config
oc create secret generic mlflow-auth-config --from-file=basic-auth.ini=basic-auth.ini
```
7. Scale the mlflow deployment back to 1.
```
oc scale deployment/mlflow --replicas=1
```
8. Verify that the data is restored correctly.

