# radon-chart

Helm chart for [Radon](https://github.com/fmidev/radon) database

## Contents

Chart contains configuration for Radon openshift deployment.

## Preconditions

Check these from values.yaml:
- The storage.storageClassName must be configured according to the options
provided by the cloud provider (e.g. gp3-csi for aws).
- serviceAccount.create must be true on the first installation.
- When installing on a non openshift cluster set the imageStream to false.

### Secrets

Necessary passwords for the database users need to be created before creating
the chart. Set the base64 encoded passwords to templates/secrets.yaml before
installation.

Generate self-signed certificates for the server with these
[instructions](https://www.postgresql.org/docs/15/ssl-tcp.html). 

```bash
oc create secret generic radon-ssl --from-file=server.key=ssl/server.key --from-file=server.crt=ssl/server.crt
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
