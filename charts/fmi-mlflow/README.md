
# Helm chart MLFlow 

## Contents

MlFlow tracking server with potgresql cluster.

https://mlflow.org/docs/3.4.0/ml/tracking/server/

## Preconditions

The following secrets needs to be created before deploying the helm chart.

* basi-auth.ini
* s3 credentials

```
oc create secret generic s3-credentials --from-env-file=aws.env
oc create secret generic mlflow-auth-config --from-file=basic-auth.ini=basic-auth.ini
```

## Image

Use the official mlflow image as a base image. Latest images can be found from [here](https://github.com/mlflow/mlflow/pkgs/container/mlflow).

All the necessary dependencies except s3 components and database drivers are baked into the image.

### Upgrading mlflow version

Ref. https://mlflow.org/docs/3.5.0/self-hosting/migration

1. Stop the server:
```
oc scale deployment/mlflow --replicas=0
```
2. Upgrade the package version in the environment:
Change the mlflow.image.tag in the `values.yaml` file to the desired version and a new build should trigger automatically after upgrading charts.

3. Run database migrations (if database backend is used):
```
oc process migrate-db -p IMAGE=<new-image-with-migrations> | oc apply -f -
```

4. Restart the server.
```
oc rollout restart deployment/mlflow
oc scale deployment/mlflow --replicas=1
```

NOTE: 
MLflow tracking server works with the older version of the SDK, up to one major version difference (e.g., 2.x to 3.x).
MLflow tracking server may not work with the newer version of the SDK.


## Create the helm release

```
helm create himan . -f values.yaml
```

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





