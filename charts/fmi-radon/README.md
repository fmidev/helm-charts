# radon-chart

Helm chart for [Radon](https://github.com/fmidev/radon) database

## Contents

Chart contains configuration for Radon openshift deployment.

## Preconditions

### Secrets

Necessary passwords for the database users need to be created before creating the chart.

```bash
oc create secret generic db-credentials --from-env-file=.env
```

### [SCC policy](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html)

SCC policy must be set because the radon database container image expects to be
run as the **postgres** user (uid: 999). If the image is run as a non-postgres
user, there won't be sufficient read/write permissions for parts of the
container file system that are required. It's possible to avoid this issue if
the image is desgined to be be run as an arbitrary user ID.

Currently, if deployed with the cloud value set as **aws** the chart expects an
SCC policy with the name **restricted-v2-uid-999**. This policy must be bound
to the service account **radondb**.

## Usage

helm create radondb . -f values.yaml
