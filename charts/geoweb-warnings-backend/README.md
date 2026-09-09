# GeoWeb Warnings Backend Helm Chart

Deploys the GeoWeb warnings backend, auth proxy sidecar, and optional development or Zalando PostgreSQL resources. CloudNativePG databases are managed separately with the `geoweb-cnpg` chart.

# Upgrade notes for chart 2.0.0

Chart `2.0.0` introduces a breaking database values cleanup. The old `warnings.db.enableDefaultDb` and `warnings.db.useZalandoOperatorDb` booleans are replaced by the new `warnings.db.mode` value, and database settings now live under common fields and mode-specific blocks. Removed 1.x database values cause template rendering to fail until they are migrated.

Migration map:

| Removed value | New value |
| - | - |
| `warnings.db.enableDefaultDb: true` | `warnings.db.mode: sidecar` |
| `warnings.db.enableDefaultDb: false` with `warnings.db.useZalandoOperatorDb: false` | `warnings.db.mode: external` |
| `warnings.db.useZalandoOperatorDb: true` | `warnings.db.mode: zalando` |
| `warnings.db_secret` | `warnings.db.external.encodedConnectionString` for `source: inline`, or `warnings.db.external.secretProvider.objectName` for `source: secretProvider` |
| `warnings.db_secretName` | `warnings.db.external.secretName` |
| `warnings.db_secretType` | `warnings.db.external.secretProvider.objectType` |
| `warnings.db_secretPath` | `warnings.db.external.secretProvider.path` |
| `warnings.db_secretKey` | `warnings.db.external.secretProvider.key` |
| `warnings.iamRoleARN` | `warnings.db.external.secretProvider.iamRoleARN` |
| `warnings.spcName` | `warnings.db.external.secretProvider.className` |
| `secretProvider` | `warnings.db.external.secretProvider.provider` |
| `secretProviderParameters` | `warnings.db.external.secretProvider.parameters` |
| `warnings.db.POSTGRES_DB` | `warnings.db.databaseName` |
| `warnings.db.POSTGRES_USER` | `warnings.db.username` |
| `warnings.db.POSTGRES_PASSWORD` | `warnings.db.sidecar.password` |
| `warnings.db.POSTGRES_VERSION` | `warnings.db.zalando.postgresVersion` |
| `warnings.db.numberOfInstances` | `warnings.db.zalando.instances` |
| `warnings.db.instanceSize` | `warnings.db.zalando.volumeSize` |
| `warnings.db.zalandoTeamId` | `warnings.db.zalando.teamId` |
| `warnings.db.enableLogicalBackup` | `warnings.db.zalando.enableLogicalBackup` |
| `warnings.db.cleanInstall: false` | `warnings.db.zalando.clone.enabled: true` |
| `warnings.db.backupTimestamp` | `warnings.db.zalando.clone.timestamp` |
| `warnings.db.backupBucket` | `warnings.db.zalando.clone.backupBucket` |

For existing Zalando deployments, render old and migrated values before upgrading and compare the generated `postgresql` resource. The resource name, users, database name, team ID, instance count, and volume size should stay unchanged.

For existing external database deployments, verify that the rendered Deployment still reads `WARNINGS_BACKEND_DB` from the intended Kubernetes Secret name and key.

An upgrade from 1.x does not require changing database technology. First migrate the values to `mode: sidecar`, `mode: zalando`, or the corresponding external source and verify the rendered resources. Moving the data to CloudNativePG is a separate operation and should not be combined with the chart values migration.

## Migrating an existing database to CloudNativePG

The `geoweb-cnpg` chart creates a new, empty database. It does not adopt or copy a 1.x sidecar, Zalando, or external database.

1. Migrate and validate the 1.x values while retaining the existing database mode.
2. Back up the source database and verify that the dump can be read.
3. Install `geoweb-cnpg` as a separate release with a different resource name from the source database.
4. Stop writes to warnings, take a final consistent dump, and restore it into the CNPG database.
5. Verify schema, row counts, and required warnings before changing the application release.
6. Upgrade warnings with `mode: external`, `source: existingSecret`, and the CNPG-generated `<cluster-name>-app` Secret key `uri`.
7. Keep the source database and backup until application validation and the rollback window are complete.

Do not uninstall the source database release as part of the application upgrade. The exact dump and restore commands depend on the source mode and environment; rehearse the procedure on a copy before production migration.

# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create required dependencies

Create a values file for the required variables.

- Using an external database connection string from AWS Secrets Manager

```yaml
warnings:
  url: geoweb.example.com
  db:
    mode: external
    external:
      source: secretProvider
      secretName: warnings-db
      secretKey: WARNINGS_BACKEND_DB
      secretProvider:
        provider: aws
        className: warnings-spc
        objectName: secretName # Secret should contain the PostgreSQL database connection string
        objectType: secretsmanager
        iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret
        parameters:
          region: your-region
```

- Using a base64-encoded connection string

```yaml
warnings:
  url: geoweb.example.com
  db:
    mode: external
    external:
      source: inline
      secretName: warnings-db
      secretKey: WARNINGS_BACKEND_DB
      encodedConnectionString: base64_encoded_postgresql_connection_string
```

- Using custom configuration files stored locally

```yaml
warnings:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

- Using custom configuration files stored in AWS S3

```yaml
warnings:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationLocation: s3
  s3bucketName: example-bucket
  customConfigurationFolderPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

- Using a Zalando Operator database

Database selection is controlled by `warnings.db.mode`.

```yaml
warnings:
  url: geoweb.example.com
  db:
    mode: zalando
    name: warnings-db
    databaseName: warnings
    username: geoweb
    zalando:
      clone:
        enabled: true
        timestamp: "2030-01-01T00:00:00+00:00"
        backupBucket: s3://<S3-bucket-name>/
```

- Using a separately managed CloudNativePG database

```yaml
warnings:
  url: geoweb.example.com
  db:
    mode: external
    external:
      source: existingSecret
      secretName: warnings-db-app
      secretKey: uri
```

Install the database separately using `charts/geoweb-cnpg` and wait for the CNPG `Cluster` to become ready before deploying warnings. Both releases must use the same namespace for this configuration. Set `secretName` to `<geoweb-cnpg name>-app`; CNPG's backup method does not change this application Secret contract.

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-warnings-backend fmi/geoweb-warnings-backend --dry-run --debug --namespace geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-warnings-backend fmi/geoweb-warnings-backend --namespace geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-warnings-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Warnings backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.warnings` | Possibility to override application version | |
| `warnings.name` | Name of backend | `warnings` |
| `warnings.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/warnings-backend/warnings-backend` |
| `warnings.commitHash` | Adds commitHash annotation to the deployment | |
| `warnings.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `warnings.url` | Url which the application can be accessed | |
| `warnings.path` | Path suffix added to url | `/warnings-backend/(.*)` |
| `warnings.svcPort` | Port used for service | `80` |
| `warnings.replicas` | Amount of replicas deployed | `1` |
| `warnings.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` | 
| `warnings.secretServiceAccount` | Service Account created for handling secrets | `warnings-service-account` |
| `warnings.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `warnings.startupProbe` | Configure main container startupProbe | see defaults from `values.yaml` |
| `warnings.livenessProbe` | Configure main container livenessProbe | see defaults from `values.yaml` |
| `warnings.readinessProbe` | Configure main container readinessProbe | see defaults from `values.yaml` |
| `warnings.env.WARNINGS_PORT_HTTP` | Port used for container | `8080` |
| `warnings.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally same as `warnings.path` without the wildcard. | `/warnings-backend` |
| `warnings.nginx.name` | Name of nginx container | `nginx` |
| `warnings.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/auth-backend/auth-backend` |
| `warnings.nginx.version` | Possibility to override Nginx version | see default from `values.yaml` |
| `warnings.nginx.ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `warnings.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | - |
| `warnings.nginx.GEOWEB_USERNAME_CLAIM` | Claim name used as a user identifier in the warnings-backend | `"email"` |
| `warnings.nginx.AUD_CLAIM` | Claim name used to get the token audience | `"aud"` |
| `warnings.nginx.AUD_CLAIM_VALUE` | Required value for the audience claim | |
| `warnings.nginx.ISS_CLAIM` | Issuer claim name used to get the token issuer | `"iss"` |
| `warnings.nginx.ISS_CLAIM_VALUE` | Required value for the issuer claim | |
| `warnings.nginx.JWKS_URI` | JSON Web Key Set URI that points to an identity provider's public key set in JSON format | |
| `warnings.nginx.GEOWEB_REQUIRE_READ_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for read operations | `"FALSE"` |
| `warnings.nginx.GEOWEB_REQUIRE_WRITE_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for write operations | `"FALSE"` |
| `warnings.nginx.ALLOW_ANONYMOUS_ACCESS` | Allow/disallow anonymous access. Note that if an access token has been passed, it is checked even if anonymous access is allowed. | `"FALSE"` |
| `warnings.nginx.BACKEND_HOST` | Warning-backend container address where Nginx reverse proxy forwards the requests | `0.0.0.0:8080` |
| `warnings.nginx.NGINX_PORT_HTTP` | Port used for Nginx reverse proxy | `80` |
| `warnings.nginx.NGINX_PORT_HTTPS` | Port used for Nginx reverse proxy when SSL is enabled | `443` |
| `warnings.nginx.TRUST_FORWARDED_HEADERS` | Trust forwarded request headers in the auth proxy | |
| `warnings.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `warnings.nginx.startupProbe` | Configure nginx container startupProbe | see defaults from `values.yaml` |
| `warnings.nginx.livenessProbe` | Configure nginx container livenessProbe | see defaults from `values.yaml` |
| `warnings.nginx.readinessProbe` | Configure nginx container readinessProbe | see defaults from `values.yaml` |
| `warnings.nginx.ENV_VAR_STRICT_MODE` | Enable check if all necessary variables for authentication and authorization are set | `false` |
| `warnings.db.mode` | Database mode *(sidecar\|external\|zalando)* | `sidecar` |
| `warnings.db.name` | Database resource or sidecar name | `warnings-db` |
| `warnings.db.databaseName` | PostgreSQL database name | `warnings` |
| `warnings.db.username` | PostgreSQL username | `geoweb` |
| `warnings.db.sidecar.image` | Sidecar PostgreSQL image | `postgres` |
| `warnings.db.sidecar.port` | Sidecar PostgreSQL port | `5432` |
| `warnings.db.sidecar.password` | Sidecar PostgreSQL password | `postgres` |
| `warnings.db.external.source` | Connection Secret source *(inline\|secretProvider\|existingSecret)* | `inline` |
| `warnings.db.external.secretName` | Kubernetes Secret containing the connection string | `warnings-db` |
| `warnings.db.external.secretKey` | Connection-string key in the Kubernetes Secret | `WARNINGS_BACKEND_DB` |
| `warnings.db.external.encodedConnectionString` | Base64-encoded connection string; required when `source: inline` | |
| `warnings.db.external.secretProvider.provider` | CSI provider *(aws\|azure\|gcp\|vault)* | |
| `warnings.db.external.secretProvider.className` | SecretProviderClass name | `warnings-spc` |
| `warnings.db.external.secretProvider.objectName` | External database-secret object identifier (resource name for GCP) | |
| `warnings.db.external.secretProvider.objectType` | External object type; defaults to `secretsmanager` for AWS and `secret` for Azure | Provider-specific |
| `warnings.db.external.secretProvider.path` | Required GCP mounted filename or Vault secret path | |
| `warnings.db.external.secretProvider.key` | Required Vault secret key | |
| `warnings.db.external.secretProvider.iamRoleARN` | IAM role used by the AWS secret provider | |
| `warnings.db.external.secretProvider.parameters` | Additional provider parameters | `{}` |
| `warnings.db.zalando.teamId` | Zalando operator team ID | `geoweb` |
| `warnings.db.zalando.postgresVersion` | PostgreSQL major version | `15` |
| `warnings.db.zalando.instances` | Zalando PostgreSQL instance count | `1` |
| `warnings.db.zalando.volumeSize` | Zalando PostgreSQL volume size | `100Mi` |
| `warnings.db.zalando.enableLogicalBackup` | Enable Zalando logical backups | `true` |
| `warnings.db.zalando.clone.enabled` | Add the Zalando clone bootstrap stanza | `false` |
| `warnings.db.zalando.clone.timestamp` | Zalando clone recovery timestamp; required when cloning is enabled | |
| `warnings.db.zalando.clone.backupBucket` | Zalando clone WAL backup path; required when cloning is enabled | |
| `warnings.useCustomConfigurationFiles` | Use custom configurations | `false` |
| `warnings.customConfigurationLocation` | Where custom configurations are located *(local\|s3)* | `local` |
| `warnings.customConfigurationFolderPath` | Path to the folder which contains custom configurations | |
| `warnings.volumeAccessMode` | Permissions of the application for the custom configurations and custom warnings PersistentVolume used | `ReadOnlyMany` |
| `warnings.volumeSize` | Size of the custom configuration and warnings PersistentVolume | `100Mi` |
| `warnings.awsAccessKeyId` | AWS_ACCESS_KEY_ID for authenticating to S3 | |
| `warnings.awsAccessKeySecret` | AWS_SECRET_ACCESS_KEY for authenticating to S3 | |
| `warnings.awsDefaultRegion` | Region where your S3 bucket is located | |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |

# Chart versions

| Chart version | warnings version |
|---------------|------------------|
| 2.0.1         | 3.1.1            |
| 2.0.0         | 3.1.1            |
| 1.3.13        | 3.1.1            |
| 1.3.12        | 3.0.0            |
| 1.3.11        | 2.1.2            |
| 1.3.10        | 2.1.1            |
| 1.3.9         | 2.0.3            |
| 1.3.8         | 2.0.1            |
| 1.3.7         | 1.17.2           |
| 1.3.6         | 1.17.0           |
| 1.3.5         | 1.16.2           |
| 1.3.4         | 1.16.1           |
| 1.3.2         | 1.15.0           |
| 1.3.1         | 1.10.6           |
| 1.3.0         | 1.10.4           |
| 1.2.4         | 1.10.2           |
| 1.2.3         | 1.10.0           |
| 1.2.2         | 1.8.1            |
| 1.2.1         | 1.7.1            |
| 1.2.0         | 1.7.1            |
| 1.1.0         | 1.5.3            |
| 1.0.1         | 1.5.3            |
| 1.0.0         | 1.5.3            |
| 0.7.3         | 1.5.3            |
| 0.7.2         | 1.5.0            |
| 0.7.1         | 1.5.0            |
| 0.6.4         | 1.2.0            |
| 0.6.3         | 0.12.0           |
| 0.6.0         | 0.11.0           |
| 0.5.2         | 0.11.0           |
| 0.5.1         | 0.9.2            |
| 0.5.0         | 0.6.3            |
| 0.4.1         | 0.6.3            |
