# GeoWeb opmet backend Helm chart

Deploys the GeoWeb opmet backend, message converter, publisher and auth proxy.
The chart can use a development PostgreSQL sidecar, a separately managed
PostgreSQL database, or a Zalando Postgres Operator database.

## Upgrading from 3.x to 4.0

Chart 4.0 replaces the database booleans with the explicit
`opmet.db.mode` value and separates publisher credentials from database
credentials. Old database and publisher-secret values cause template rendering
to fail until they are migrated.

Upgrade the chart configuration without changing database technology. For an
existing Zalando deployment, select `mode: zalando` and keep the existing
cluster name, database, owner and storage settings. Moving data to another
PostgreSQL installation is a separate operation.

| 3.x value | 4.0 value |
| --- | --- |
| `opmet.db.enableDefaultDb: true` | `opmet.db.mode: sidecar` |
| `opmet.db.useZalandoOperatorDb: true` | `opmet.db.mode: zalando` |
| Both database booleans `false` | `opmet.db.mode: external` |
| `opmet.db.POSTGRES_DB` | `opmet.db.databaseName` |
| `opmet.db.POSTGRES_USER` | `opmet.db.username` |
| `opmet.db.image` | `opmet.db.sidecar.image` |
| `opmet.db.port` | `opmet.db.sidecar.port` |
| `opmet.db.POSTGRES_PASSWORD` | `opmet.db.sidecar.password` |
| `opmet.db.POSTGRES_VERSION` | `opmet.db.zalando.postgresVersion` |
| `opmet.db.numberOfInstances` | `opmet.db.zalando.instances` |
| `opmet.db.instanceSize` | `opmet.db.zalando.volumeSize` |
| `opmet.db.zalandoTeamId` | `opmet.db.zalando.teamId` |
| `opmet.db.enableLogicalBackup` | `opmet.db.zalando.enableLogicalBackup` |
| `opmet.db.cleanInstall: false` | `opmet.db.zalando.clone.enabled: true` |
| `opmet.db.backupTimestamp` | `opmet.db.zalando.clone.timestamp` |
| `opmet.db.backupBucket` | `opmet.db.zalando.clone.backupBucket` |
| Inline `opmet.db_secret` | `opmet.db.external.encodedConnectionString` |
| Provider-backed `opmet.db_secret` | `opmet.db.external.secretProvider.objectName` |
| `opmet.db_secretName` | `opmet.db.external.secretName` |
| `secretProvider` for the database | `opmet.db.external.secretProvider.provider` |
| `secretProviderParameters` for the database | `opmet.db.external.secretProvider.parameters` |
| `opmet.spcName` for the database | `opmet.db.external.secretProvider.className` |
| `opmet.ssh_secrets` | `opmet.publisher.secrets.sshKeys` |
| `opmet.ssh_passphrase_secrets` | `opmet.publisher.secrets.sshPassphrases` |
| `secretProvider` for publisher secrets | `opmet.publisher.secrets.provider` |
| `secretProviderParameters` for publisher secrets | `opmet.publisher.secrets.parameters` |
| `opmet.spcName` for publisher secrets | `opmet.publisher.secrets.className` |

For provider-backed publisher entries, rename `secret` to `objectName` and
`type` to `objectType`. For inline entries, rename `secret` to `encodedValue`.
The entry `name` remains the Kubernetes Secret name. The pod-level
`opmet.secretServiceAccount` and `opmet.iamRoleARN` values remain unchanged.

When the old shared `SecretProviderClass` contained both database and publisher
objects, configure both new provider blocks. Chart 4.0 creates independent
`SecretProviderClass` resources and mounts so changing the database cannot
remove publisher credentials. Kubernetes still assigns one service account to
the pod, so AWS permissions for both providers must be available through that
identity.

## Migrating an existing database to CloudNativePG

The `geoweb-cnpg` chart creates a new, empty database. It does not adopt or
copy a 3.x sidecar, Zalando, or external database.

1. Migrate and validate the 3.x values while retaining the existing database mode.
2. Back up the source database and verify that the dump can be read.
3. Install `geoweb-cnpg` as a separate release with a different resource name from the source database.
4. Stop writes to opmet, take a final consistent dump, and restore it into the CNPG database.
5. Verify the schema, row counts, and required aviation products before changing the application release.
6. Upgrade opmet with `mode: external`, `source: existingSecret`, and the CNPG-generated `<cluster-name>-app` Secret key `uri`.
7. Keep the source database and backup until application validation and the rollback window are complete.

Do not uninstall the source database release as part of the application
upgrade. The exact dump and restore commands depend on the source mode and
environment; rehearse the procedure on a copy before production migration.

## Database modes

The default `sidecar` mode is intended for development:

```yaml
opmet:
  db:
    mode: sidecar
```

Existing Zalando deployments can retain their database:

```yaml
opmet:
  db:
    mode: zalando
    name: opmet-db
    databaseName: opmet
    username: geoweb
    zalando:
      teamId: geoweb
      postgresVersion: 15
      instances: 2
      volumeSize: 10Gi
      enableLogicalBackup: true
      clone:
        enabled: false
```

For any externally managed PostgreSQL database, reference a Kubernetes Secret
containing a complete SQLAlchemy-compatible connection string:

```yaml
opmet:
  db:
    mode: external
    external:
      source: existingSecret
      secretName: application-database
      secretKey: connectionString
```

For a connection string stored in AWS Secrets Manager:

```yaml
opmet:
  secretServiceAccount: opmet-service-account
  iamRoleARN: arn:aws:iam::123456789012:role/opmet-secrets
  db:
    mode: external
    external:
      source: secretProvider
      secretName: opmet-db
      secretKey: OPMET_BACKEND_DB
      secretProvider:
        provider: aws
        className: opmet-db-spc
        objectName: opmet/database/connection-string
        objectType: secretsmanager
        parameters:
          region: eu-north-1
```

CloudNativePG requires no application-chart integration. Install the
`geoweb-cnpg` chart as a separate release and use its generated application
Secret like any other existing Secret:

```yaml
opmet:
  db:
    mode: external
    external:
      source: existingSecret
      secretName: opmet-db-app
      secretKey: uri
```

The database must be reachable from the opmet pod. For the CNPG example, both
releases normally use the same namespace because Kubernetes Secrets are
namespace-scoped and the generated URI uses a namespace-local service name.

To create the connection Secret from an encoded value, use `source: inline`.
To synchronize it through the Secrets Store CSI driver, use
`source: secretProvider` and configure the provider block under
`opmet.db.external`. The CSI volume is mounted only into the backend container.

## Publisher secrets

Publisher SSH credentials have their own configuration and volume. They remain
available regardless of database mode. For AWS Secrets Manager:

```yaml
opmet:
  secretServiceAccount: opmet-service-account
  iamRoleARN: arn:aws:iam::123456789012:role/opmet-secrets
  publisher:
    secrets:
      provider: aws
      className: opmet-publisher-spc
      parameters:
        region: eu-north-1
      sshKeys:
        - name: publisher-key
          objectName: opmet/publisher/private-key
          objectType: secretsmanager
      sshPassphrases:
        - name: PUBLISHER_KEY_PASSPHRASE
          objectName: opmet/publisher/passphrase
          objectType: secretsmanager
```

Leave `provider` empty and use `encodedValue` instead of `objectName` to create
the publisher Secrets directly from base64-encoded values. Do not store such
values in Git.

## Custom configuration files

Set `opmet.useCustomConfigurationFiles` and select `local` or `s3` with
`opmet.customConfigurationLocation`. Configure the existing S3 and mount values
as required for the selected source.

## OpenShift runtime

Gunicorn 25.1 and newer enable a local control socket by default. OpenShift's
arbitrary application UID may not be able to create the default socket below
`$HOME`. If the deployment does not use `gunicornc`, disable the socket in the
environment-specific values:

```yaml
opmet:
  env:
    GUNICORN_CMD_ARGS: "--no-control-socket"
```

Environments that use the control interface should leave it enabled and set
`XDG_RUNTIME_DIR` to an appropriate writable runtime directory instead.

## Testing the chart
Execute the following for testing the chart:

```bash
helm install geoweb-opmet-backend fmi/geoweb-opmet-backend --dry-run --debug --namespace geoweb --values=./values.yaml
```

## Installing the chart

Execute the following for installing the chart:

```bash
helm install geoweb-opmet-backend fmi/geoweb-opmet-backend --namespace geoweb --values=./values.yaml
```

## Deleting the chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-opmet-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

## Chart configuration
The following table lists the configurable parameters of the Opmet backend chart and their default values.

| Parameter                                     | Description | Default                                                                                      |
|-----------------------------------------------| - |----------------------------------------------------------------------------------------------|
| `ingress.customAnnotations`                   | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set |                                                                                              |
| `ingress.ingressClassName`                    | Set ingressClassName parameter to not use default ingressClass | `nginx`                                                                                      |
| `ingress.name`                                | Name of the ingress controller in use | `nginx-ingress-controller`                                                                   |
| `ingress.tls`                                 | TLS configuration section for the ingress | |
| `opmet.awsAccessKeyId`                        | AWS_ACCESS_KEY_ID for authenticating to S3 |                                                                                              |
| `opmet.awsAccessKeySecret`                    | AWS_SECRET_ACCESS_KEY for authenticating to S3 |                                                                                              |
| `opmet.awsDefaultRegion`                      | Region where your S3 bucket is located |                                                                                              |
| `opmet.commitHash`                            | Adds commitHash annotation to the deployment |                                                                                              |
| `opmet.customConfigurationFolderPath`         | Path to the folder which contains custom configurations |                                                                                              |
| `opmet.customConfigurationLocation`           | Where custom configurations are located *(local\|s3)* | `local`                                                                                      |
| `opmet.customConfigurationMountPath`          | Folder used to mount custom configurations | `/app/configuration_files/custom`                                                            |
| `opmet.db.mode`                               | Database mode *(sidecar\|external\|zalando)* | `sidecar` |
| `opmet.db.name`                               | Sidecar container or Zalando database resource name | `opmet-db` |
| `opmet.db.databaseName`                       | Application database name | `opmet` |
| `opmet.db.username`                           | Application database owner/login | `geoweb` |
| `opmet.db.sidecar.image`                      | Development PostgreSQL image | `postgres` |
| `opmet.db.sidecar.port`                       | Development PostgreSQL port | `5432` |
| `opmet.db.sidecar.password`                   | Development PostgreSQL password | `postgres` |
| `opmet.db.external.source`                    | Connection Secret source *(inline\|secretProvider\|existingSecret)* | `inline` |
| `opmet.db.external.secretName`                | Kubernetes Secret containing the connection string | `opmet-db` |
| `opmet.db.external.secretKey`                 | Connection-string key in the Kubernetes Secret | `OPMET_BACKEND_DB` |
| `opmet.db.external.encodedConnectionString`   | Base64 connection string used by `inline` | See `values.yaml` |
| `opmet.db.external.secretProvider.provider`   | CSI provider *(aws\|azure\|gcp\|vault)* | |
| `opmet.db.external.secretProvider.className`  | Database SecretProviderClass name | `opmet-db-spc` |
| `opmet.db.external.secretProvider.objectName` | External database-secret object name | |
| `opmet.db.external.secretProvider.objectType` | External object type for AWS or Azure | `secretsmanager` |
| `opmet.db.external.secretProvider.path`       | Provider-specific secret path | |
| `opmet.db.external.secretProvider.key`        | Provider-specific secret key | |
| `opmet.db.external.secretProvider.parameters` | Additional provider parameters | `{}` |
| `opmet.db.zalando.teamId`                     | Zalando team ID | `geoweb` |
| `opmet.db.zalando.postgresVersion`            | Zalando PostgreSQL major version | `15` |
| `opmet.db.zalando.instances`                  | Zalando database instance count | `1` |
| `opmet.db.zalando.volumeSize`                 | Zalando database volume size | `100Mi` |
| `opmet.db.zalando.enableLogicalBackup`        | Enable Zalando logical backups | `true` |
| `opmet.db.zalando.clone.enabled`              | Restore a Zalando cluster from backup | `false` |
| `opmet.db.zalando.clone.timestamp`            | Zalando restore timestamp | `"2030-01-01T00:00:00+00:00"` |
| `opmet.db.zalando.clone.backupBucket`         | Zalando backup bucket | |
| `opmet.env.AIRMET_CONFIG`                     | Location of AIRMET configuration file that is used (application defaults to `configuration_files/airmetConfig.json`) |                                                                                              |
| `opmet.env.BACKEND_CONFIG`                    | Location of backend configuration file that is used (application defaults to `configuration_files/backendConfig.json`) |                                                                                              |
| `opmet.env.OPMET_BACKEND_PORT_HTTP`           | Port used for container | `8000`                                                                                       |
| `opmet.env.MESSAGECONVERTER_URL`              | - | `"http://localhost:8080"`                                                                    |
| `opmet.env.PUBLISHER_URL`                     | - | `"http://localhost:8090/publish"`                                                            |
| `opmet.env.APPLICATION_ROOT_PATH`             | Application root path for FastAPI. Generally same as `opmet.path` without the wildcard. | `/opmet`                                                                                |
| `opmet.env.SIGMET_CONFIG`                     | Location of SIGMET configuration file that is used (application defaults to `configuration_files/sigmetConfig.json`) |                                                                                              |
| `opmet.iamRoleARN`                            | IAM Role with permissions to access secrets |                                                                                              |
| `opmet.imagePullPolicy`                       | Adds option to modify imagePullPolicy |                                                                                              |
| `opmet.livenessProbe`                         | Configure main container livenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.messageconverter.livenessProbe`        | Configure message converter livenessProbe | see defaults from `values.yaml`                                                              |     |
| `opmet.messageconverter.name`                 | Name of messageconverter container | `opmet-messageconverter`                                                                     |
| `opmet.messageconverter.port`                 | Port used for messageconverter | `8080`                                                                                       |
| `opmet.messageconverter.readinessProbe`       | Configure message converter readinessProbe | see defaults from `values.yaml`                                                         
| `opmet.messageconverter.registry`             | Registry to fetch image | `registry.gitlab.com/opengeoweb/avi-msgconverter/geoweb-knmi-avi-messageservices`            |
| `opmet.messageconverter.resources`            | Configure resource limits & requests | see defaults from `values.yaml`                                                              |
| `opmet.messageconverter.startupProbe`         | Configure message converter startupProbe | see defaults from `values.yaml`                                                            
| `opmet.messageconverter.version`              | Possibility to override application version | see default from `values.yaml`                                                               |
| `opmet.minPodsAvailable`                      | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0`                                                                                          |
| `opmet.name`                                  | Name of backend | `opmet`                                                                                      |
| `opmet.nginx.ALLOW_ANONYMOUS_ACCESS`          | Allow/disallow anonymous access. Note that if an access token has been passed, it is checked even if anonymous access is allowed | `"FALSE"` |
| `opmet.nginx.AUD_CLAIM`                       | Claim name used to get the token audience | `"aud"` |
| `opmet.nginx.AUD_CLAIM_VALUE`                 | Required value for the audience claim |  |
| `opmet.nginx.BACKEND_HOST`                    | Address where nginx accesses the backend | `localhost:8080`                                                                             |
| `opmet.nginx.ENABLE_SSL`                      | Toggle SSL termination | `"FALSE"`                                                                                    |
| `opmet.nginx.GEOWEB_REQUIRE_READ_PERMISSION`  | Required OAUTH claim name and value to be present in the userinfo response for read operations | `"FALSE"`                                                                                    |
| `opmet.nginx.GEOWEB_REQUIRE_WRITE_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for write operations | `"FALSE"`                                                                                    |
| `opmet.nginx.GEOWEB_USERNAME_CLAIM`           | Claim name used as a user identifier in the opmet backend | `"email"`|
| `opmet.nginx.ISS_CLAIM`                       | Issuer claim name used to get the token issuer | `"iss"` |
| `opmet.nginx.ISS_CLAIM_VALUE`                 | Required value for the issuer claim |  |
| `opmet.nginx.JWKS_URI`                        | JSON Web Key Set URI that points to an identity provider's public key set in JSON format |  |
| `opmet.nginx.livenessProbe`                   | Configure nginx container livenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.nginx.name`                            | Name of nginx container | `opmet-nginx`                                                                                |
| `opmet.nginx.NGINX_PORT_HTTP`                 | Port used for nginx | `80`                                                                                         |
| `opmet.nginx.NGINX_PORT_HTTPS`                | Port used for nginx when SSL is enabled | `443`                                                                                        |
| `opmet.nginx.TRUST_FORWARDED_HEADERS`         | Preserve incoming `X-Forwarded-*` headers when running behind a trusted proxy | Auth proxy default |
| `opmet.nginx.OAUTH2_USERINFO`                 | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | |
| `opmet.nginx.readinessProbe`                  | Configure nginx container readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.nginx.registry`                        | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/auth-backend/auth-backend`          |
| `opmet.nginx.resources`                       | Configure resource limits & requests | see defaults from `values.yaml`|
| `opmet.nginx.startupProbe  `                  | Configure nginx container startupProbe | see defaults from `values.yaml`                                                              |
| `opmet.nginx.version`                         | Possibility to override Nginx version | see default from `values.yaml` |
| `opmet.nginx.ENV_VAR_STRICT_MODE`             | Enable check if all necessary variables for authentication and authorization are set | `false` |
| `opmet.path`                                  | Path suffix added to url | `/opmet/(.*)`                                                                                |
| `opmet.publisher.DESTINATION`                 | Folder inside publisher container where TACs are stored (used with local-publisher) | `/app/output`                                                                                |
| `opmet.publisher.livenessProbe`               | Configure publisher livenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.publisher.name`                        | Name of publisher container  | `opmet-publisher`                                                                            |
| `opmet.publisher.port`                        | Port used for publisher | `8090`                                                                                       |
| `opmet.publisher.readinessProbe`              | Configure publisher readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.publisher.registry`                    | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend/opmet-backend-publisher-local` |
| `opmet.publisher.resources`                   | Configure resource limits & requests | see defaults from `values.yaml`                                                              |
| `opmet.publisher.S3_BUCKET_NAME`              | S3 Bucket used to publish files to |                                                                                              |
| `opmet.publisher.SERVERS`                     | List of configuration options used to access SFTP server. List of jsons. Note that ssh secrets get mounted to `/mnt/secrets-store`. Details https://gitlab.com/opengeoweb/backend-services/opmet-backend#sftp-publisher |                                                                                              |
| `opmet.publisher.secrets.provider`            | Publisher CSI provider; empty creates inline Secrets *(aws\|azure\|gcp\|vault)* | |
| `opmet.publisher.secrets.className`           | Publisher SecretProviderClass name | `opmet-publisher-spc` |
| `opmet.publisher.secrets.parameters`          | Additional publisher provider parameters | `{}` |
| `opmet.publisher.secrets.sshKeys`             | Publisher SSH-key entries | `[]` |
| `opmet.publisher.secrets.sshPassphrases`      | Publisher SSH-passphrase entries | `[]` |
| `opmet.publisher.startupProbe`              | Configure publisher startupProbe | see defaults from `values.yaml`                                                              |
| `opmet.publisher.version`                     | Publisher version | defaults to Chart.AppVersion                                                                 |
| `opmet.publisher.volumeOptions`               | yaml including the definition of the volume where TACs are published to, for example: <pre>hostPath:<br>&nbsp;&nbsp; path: /test/path</pre> or <pre>emptyDir:<br>&nbsp;&nbsp;</pre>| `emptyDir:`                                                                                  |
| `opmet.readinessProbe`                        | Configure main container readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.registry`                              | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend`                              |
| `opmet.replicas`                              | Amount of replicas deployed | `1`                                                                                          |
| `opmet.resources`                             | Configure resource limits & requests | see defaults from `values.yaml`                                                              |
| `opmet.s3bucketName`                          | Name of the S3 bucket where custom configurations are stored |                                                                                              |
| `opmet.secretServiceAccount`                  | Service Account created for handling secrets | `opmet-service-account`                                                                      |
| `opmet.startupProbe`                          | Configure main container startupProbe | see defaults from `values.yaml`                                                              |  |
| `opmet.svcPort`                               | Port used for service | `80`                                                                                         |
| `opmet.url`                                   | Url which the application can be accessed |                                                                                              |
| `opmet.useCustomConfigurationFiles`           | Use custom configurations | `false`                                                                                      |
| `opmet.volumeAccessMode`                      | Permissions of the application for the custom configurations PersistentVolume used | `ReadOnlyMany`                                                                               |
| `opmet.volumeSize`                            | Size of the custom configurations PersistentVolume | `100Mi`                                                                                      |
| `versions.opmet`                              | Possibility to override application version |                                                                                              |

## Chart versions

| Chart version | opmet version |
|---------------|---------------|
| 4.0.0         | 5.11.0        |
| 3.10.16       | 5.11.0        |
| 3.10.15       | 5.10.2        |
| 3.10.14       | 5.10.0        |
| 3.10.13       | 5.8.2         |
| 3.10.12       | 5.8.0         |
| 3.10.11       | 5.8.0         |
| 3.10.10       | 5.8.0         |
| 3.10.9        | 5.8.0         |
| 3.10.8        | 5.6.2         |
| 3.10.7        | 5.6.1         |
| 3.10.6        | 5.5.0         |
| 3.10.4        | 5.4.0         |
| 3.10.3        | 5.3.1         |
| 3.10.1        | 5.1.1         |
| 3.10.0        | 4.1.0         |
| 3.9.4         | 4.1.0         |
| 3.9.3         | 3.6.2         |
| 3.9.2         | 3.6.1         |
| 3.9.1         | 3.5.1         |
| 3.9.0         | 3.4.2         |
| 3.8.4         | 3.4.2         |
| 3.8.3         | 3.4.0         |
| 3.8.2         | 3.4.0         |
| 3.8.1         | 3.2.0         |
| 3.8.0         | 3.1.2         |
| 3.7.2         | 3.1.2         |
| 3.7.1         | 3.1.0         |
| 3.7.0         | 3.0.1         |
| 3.6.0         | 3.0.1         |
| 3.5.4         | 3.0.1         |
| 3.5.3         | 3.0.0         |
| 3.5.2         | 3.0.0         |
| 3.5.1         | 3.0.0         |
| 3.5.0         | 2.12.1        |
| 3.4.4         | 2.12.1        |
| 3.4.3         | 2.11.0        |
| 3.4.2         | 2.10.1        |
| 3.4.1         | 2.9.2         |
| 3.4.0         | 2.9.1         |
| 3.2.0         | 2.7.0         |
