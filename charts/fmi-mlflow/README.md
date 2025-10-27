
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

