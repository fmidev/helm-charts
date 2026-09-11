# GeoWeb TAF Backend Helm Chart

Deploys the GeoWeb TAF backend, placeholder, message converter, publisher, auth proxy, and optional development or Zalando PostgreSQL resources. CloudNativePG databases are managed separately with the `geoweb-cnpg` chart.

# Upgrade notes for chart 2.0.0

Chart `2.0.0` introduces a breaking database values cleanup. The old `taf.db.enableDefaultDb` and `taf.db.useZalandoOperatorDb` booleans are replaced by `taf.db.mode`, and database settings now live under common fields and mode-specific blocks. Removed 1.x database values cause template rendering to fail until they are migrated.

Migration map:

| Removed value | New value |
| - | - |
| `taf.db.enableDefaultDb: true` | `taf.db.mode: sidecar` |
| `taf.db.enableDefaultDb: false` with `taf.db.useZalandoOperatorDb: false` | `taf.db.mode: external` |
| `taf.db.useZalandoOperatorDb: true` | `taf.db.mode: zalando` |
| `taf.db_secret` | `taf.db.external.encodedConnectionString` for `source: inline`, or `taf.db.external.secretProvider.objectName` for `source: secretProvider` |
| `taf.db_secretName` | `taf.db.external.secretName` |
| `taf.db_secretType` | `taf.db.external.secretProvider.objectType` |
| `taf.db_secretPath` | `taf.db.external.secretProvider.path` |
| `taf.db_secretKey` | `taf.db.external.secretProvider.key` |
| `taf.iamRoleARN` | `taf.db.external.secretProvider.iamRoleARN` |
| `taf.spcName` | `taf.db.external.secretProvider.className` |
| `secretProvider` | `taf.db.external.secretProvider.provider` |
| `secretProviderParameters` | `taf.db.external.secretProvider.parameters` |
| `taf.db.POSTGRES_DB` | `taf.db.databaseName` |
| `taf.db.POSTGRES_USER` | `taf.db.username` |
| `taf.db.image` | `taf.db.sidecar.image` |
| `taf.db.port` | `taf.db.sidecar.port` |
| `taf.db.POSTGRES_PASSWORD` | `taf.db.sidecar.password` |
| `taf.db.POSTGRES_VERSION` | `taf.db.zalando.postgresVersion` |
| `taf.db.numberOfInstances` | `taf.db.zalando.instances` |
| `taf.db.instanceSize` | `taf.db.zalando.volumeSize` |
| `taf.db.zalandoTeamId` | `taf.db.zalando.teamId` |
| `taf.db.enableLogicalBackup` | `taf.db.zalando.enableLogicalBackup` |
| `taf.db.cleanInstall: false` | `taf.db.zalando.clone.enabled: true` |
| `taf.db.backupTimestamp` | `taf.db.zalando.clone.timestamp` |
| `taf.db.backupBucket` | `taf.db.zalando.clone.backupBucket` |

For existing Zalando deployments, render old and migrated values before upgrading and compare the generated `postgresql` resource. Preserve the resource name, users, database name, team ID, instance count, PostgreSQL version, volume size, backup setting, and clone configuration.

For existing external database deployments, verify that both the TAF API and placeholder containers still read `AVIATION_TAF_BACKEND_DB` from the intended Kubernetes Secret name and key. Publisher configuration is independent from database selection.

An upgrade from 1.x does not require changing database technology. First migrate the values while retaining the existing database mode. Moving data to CloudNativePG is a separate operation and should not be combined with the chart values migration.

## Migrating an existing database to CloudNativePG

The `geoweb-cnpg` chart creates a new database lifecycle; this application chart does not adopt or copy a sidecar, Zalando, or other external database.

1. Migrate and validate the 1.x values while retaining the existing database mode.
2. Back up the source database and verify that the dump can be read.
3. Install `geoweb-cnpg` as a separate release with a different resource name from the source database.
4. Stop writes to TAF, take a final consistent dump, and restore it into the CNPG database.
5. Verify schema, row counts, and representative TAF operations before changing the application release.
6. Upgrade TAF with `mode: external`, `source: existingSecret`, and the CNPG-generated `<cluster-name>-app` Secret key `uri`.
7. Keep the source database and backup until application validation and the rollback window are complete.

Do not uninstall the source database release as part of the application upgrade. Rehearse the exact dump and restore procedure on a copy before production migration.

# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create required dependencies

Create your own values file for required variables.

* Using AWS Secrets Manager for an external database connection string

```yaml
taf:
  url: geoweb.example.com
  db:
    mode: external
    external:
      source: secretProvider
      secretName: taf-db
      secretKey: AVIATION_TAF_BACKEND_DB
      secretProvider:
        provider: aws
        className: taf-spc
        objectName: secretName
        iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret
        parameters:
          region: your-region
```

* Creating a Secret from an inline base64-encoded connection string

```yaml
taf:
  url: geoweb.example.com
  db:
    mode: external
    external:
      source: inline
      secretName: taf-db
      secretKey: AVIATION_TAF_BACKEND_DB
      encodedConnectionString: base64_encoded_postgresql_connection_string
```

* Using an existing Secret, including one generated by `geoweb-cnpg`

```yaml
taf:
  url: geoweb.example.com
  db:
    mode: external
    external:
      source: existingSecret
      secretName: taf-db-app
      secretKey: uri
```

* Using custom configuration files stored locally
```yaml
taf:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

* Using custom configuration files stored in AWS S3
```yaml
taf:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationLocation: s3
  s3bucketName: example-bucket
  customConfigurationFolderPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

* Using Zalando Operator Database

```yaml
taf:
  url: geoweb.example.com
  db:
    mode: zalando
    name: taf-db
    databaseName: taf
    username: geoweb
    zalando:
      teamId: geoweb
      postgresVersion: 15
      instances: 2
      volumeSize: 1Gi
      enableLogicalBackup: true
      clone:
        enabled: false
```

To create a new Zalando database, keep `clone.enabled: false`. Enable cloning only when restoring an existing cluster and provide both a valid recovery timestamp and backup bucket.

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-taf-backend fmi/geoweb-taf-backend --dry-run --debug --namespace geoweb --values=./<yourvaluesfile>.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-taf-backend fmi/geoweb-taf-backend --namespace geoweb --values=./<yourvaluesfile>.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-taf-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Taf backend chart and their default values specified in file values.yaml.

| Parameter | Description | Default |
| - | - | - |
| `versions.taf` | Possibility to override application version | |
| `taf.name` | Name of backend | `taf` |
| `taf.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/aviation-taf-backend` |
| `taf.commitHash` | Adds commitHash annotation to the deployment | |
| `taf.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `taf.url` | Url which the application can be accessed | |
| `taf.path` | Path suffix added to url | `/taf-backend/(.*)` |
| `taf.svcPort` | Port used for service | `80` |
| `taf.replicas` | Amount of replicas deployed | `1` |
| `taf.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` |
| `taf.secretServiceAccount` | Service Account created for handling secrets | `taf-service-account` |
| `taf.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.startupProbe` | Configure main container startupProbe | see defaults from `values.yaml` |
| `taf.livenessProbe` | Configure main container livenessProbe | see defaults from `values.yaml` |
| `taf.readinessProbe` | Configure main container readinessProbe | see defaults from `values.yaml` |
| `taf.env.AVIATION_TAF_PORT_HTTP` | Port used for container | `8000` |
| `taf.env.GEOWEB_KNMI_AVI_MESSAGESERVICES_HOST` | - | `"localhost:8081"` |
| `taf.env.AVIATION_TAF_PUBLISH_HOST` | - | `"localhost:8090"` |
| `taf.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally same as `taf.path` without the wildcard. | `/taf-backend`
| `taf.useCustomConfigurationFiles` | Use custom configurations | `false` |
| `taf.customConfigurationLocation` | Where custom configurations are located *(local\|s3)* | `local` |
| `taf.volumeAccessMode` | Permissions of the application for the custom configurations PersistentVolume used | `ReadOnlyMany` |
| `taf.volumeSize` | Size of the custom configurations PersistentVolume | `100Mi` |
| `taf.customConfigurationFolderPath` | Path to the folder which contains custom configurations | |
| `taf.customConfigurationMountPath` | Folder used to mount custom configurations | `/app/custom` |
| `taf.s3bucketName` | Name of the S3 bucket where custom configurations are stored | |
| `taf.awsAccessKeyId` | AWS_ACCESS_KEY_ID for authenticating to S3 | |
| `taf.awsAccessKeySecret` | AWS_SECRET_ACCESS_KEY for authenticating to S3 | |
| `taf.awsDefaultRegion` | Region where your S3 bucket is located | |
| `taf.messageconverter.name` | Name of messageconverter container | `taf-messageconverter` |
| `taf.messageconverter.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/avi-msgconverter/geoweb-knmi-avi-messageservices` |
| `taf.messageconverter.version` | Possibility to override application version | see default from `values.yaml` |
| `taf.messageconverter.port` | Port used for messageconverter | `8081` |
| `taf.messageconverter.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.messageconverter.startupProbe` | Configure message converter startupProbe | see defaults from `values.yaml` |
| `taf.messageconverter.livenessProbe` | Configure message converter livenessProbe | see defaults from `values.yaml` |
| `taf.messageconverter.readinessProbe` | Configure message converter readinessProbe | see defaults from `values.yaml` |
| `taf.nginx.name` | Name of nginx container | `taf-nginx` |
| `taf.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/auth-backend/auth-backend` |
| `taf.nginx.version` | Possibility to override Nginx version | see default from `values.yaml` |
| `taf.nginx.ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `taf.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | |
| `taf.nginx.GEOWEB_USERNAME_CLAIM` | Claim name used as a user identifier in the taf-backend | `"email"` |
| `taf.nginx.AUD_CLAIM` | Claim name used to get the token audience | `"aud"` |
| `taf.nginx.AUD_CLAIM_VALUE` | Required value for the audience claim | |
| `taf.nginx.ISS_CLAIM` | Issuer claim name used to get the token issuer | `"iss"` |
| `taf.nginx.ISS_CLAIM_VALUE` | Required value for the issuer claim | |
| `taf.nginx.JWKS_URI` | JSON Web Key Set URI that points to an identity provider's public key set in JSON format | |
| `taf.nginx.GEOWEB_REQUIRE_READ_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for read operations | `"FALSE"` |
| `taf.nginx.GEOWEB_REQUIRE_WRITE_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for write operations | `"FALSE"` |
| `taf.nginx.ALLOW_ANONYMOUS_ACCESS` | Allow/disallow anonymous access. Note that if an access token has been passed, it is checked even if anonymous access is allowed. | `"FALSE"` |
| `taf.nginx.BACKEND_HOST` | TAF-backend container address where Nginx reverse proxy forwards the requests | `localhost:8000` |
| `taf.nginx.NGINX_PORT_HTTP` | Port used for Nginx reverse proxy | `80` |
| `taf.nginx.NGINX_PORT_HTTPS` | Port used for Nginx reverse proxy when SSL is enabled | `443` |
| `taf.nginx.NGINX_ENTRYPOINT_WORKER_PROCESSES_AUTOTUNE` | Tune Nginx worker processes to the container CPU limit when supported by the auth-backend image | Auth proxy default |
| `taf.nginx.TRUST_FORWARDED_HEADERS` | Preserve incoming `X-Forwarded-*` headers only behind a trusted proxy that sanitizes them | Auth proxy default |
| `taf.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.nginx.startupProbe` | Configure nginx container startupProbe | see defaults from `values.yaml` |
| `taf.nginx.livenessProbe` | Configure nginx container livenessProbe | see defaults from `values.yaml` |
| `taf.nginx.readinessProbe` | Configure nginx container readinessProbe | see defaults from `values.yaml` |
| `taf.nginx.ENV_VAR_STRICT_MODE` | Enable check if all necessary variables for authentication and authorization are set | `false` |
| `taf.publisher.name` | Name of publisher container  | `taf-publisher` |
| `taf.publisher.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/aviation-taf-backend-publisher-local` |
| `taf.publisher.port` | Port used for publisher | `8090`|
| `taf.publisher.PUBLISH_DIR` | Folder inside publisher container where TACs are stored | `/app/output` |
| `taf.publisher.volumeOptions` | yaml including the definition of the volume where TACs are published to, for example: <pre>hostPath:<br>&nbsp;&nbsp; path: /test/path</pre> or <pre>emptyDir:<br>&nbsp;&nbsp;</pre>| `emptyDir:` |
| `taf.publisher.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.publisher.livenessProbe` | Configure livenessProbe | see defaults from `values.yaml` |
| `taf.publisher.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `taf.placeholder.name` | Name of publisher container  | `taf-placeholder` |
| `taf.placeholder.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/tafplaceholder-aviation-taf-backend` |
| `taf.placeholder.TAFPLACEHOLDER_KEEPRUNNING` | - | `TRUE` |
| `taf.placeholder.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.placeholder.startupProbe` | Configure placeholder container startupProbe | see defaults from `values.yaml` |
| `taf.placeholder.livenessProbe` | Configure placeholder container livenessProbe | see defaults from `values.yaml` |
| `taf.placeholder.readinessProbe` | Configure placeholder container readinessProbe | see defaults from `values.yaml` |
| `taf.db.mode` | Database mode *(sidecar\|external\|zalando)* | `sidecar` |
| `taf.db.name` | Sidecar container or Zalando database resource name | `taf-db` |
| `taf.db.databaseName` | Application database name | `taf` |
| `taf.db.username` | Application database owner/login | `geoweb` |
| `taf.db.sidecar.image` | Development PostgreSQL image | `postgres` |
| `taf.db.sidecar.port` | Development PostgreSQL port | `5432` |
| `taf.db.sidecar.password` | Development PostgreSQL password | `postgres` |
| `taf.db.external.source` | Connection Secret source *(inline\|secretProvider\|existingSecret)* | `inline` |
| `taf.db.external.secretName` | Kubernetes Secret containing the connection string | `taf-db` |
| `taf.db.external.secretKey` | Connection-string key in the Kubernetes Secret | `AVIATION_TAF_BACKEND_DB` |
| `taf.db.external.encodedConnectionString` | Base64 connection string; required when `source: inline` | |
| `taf.db.external.secretProvider.provider` | CSI provider *(aws\|azure\|gcp\|vault)* | |
| `taf.db.external.secretProvider.className` | Database SecretProviderClass name | `taf-spc` |
| `taf.db.external.secretProvider.objectName` | External database-secret object identifier (resource name for GCP) | |
| `taf.db.external.secretProvider.objectType` | External object type; defaults to `secretsmanager` for AWS and `secret` for Azure | `""` |
| `taf.db.external.secretProvider.path` | Required GCP mounted filename or Vault secret path | |
| `taf.db.external.secretProvider.key` | Required Vault secret key | |
| `taf.db.external.secretProvider.iamRoleARN` | IAM role for AWS database-secret access | |
| `taf.db.external.secretProvider.parameters` | Additional provider parameters | `{}` |
| `taf.db.zalando.teamId` | Zalando team ID | `geoweb` |
| `taf.db.zalando.postgresVersion` | Zalando PostgreSQL major version | `15` |
| `taf.db.zalando.instances` | Zalando database instance count | `1` |
| `taf.db.zalando.volumeSize` | Zalando database volume size | `100Mi` |
| `taf.db.zalando.enableLogicalBackup` | Enable Zalando logical backups | `true` |
| `taf.db.zalando.clone.enabled` | Restore a Zalando cluster from backup | `false` |
| `taf.db.zalando.clone.timestamp` | Zalando restore timestamp; required when cloning is enabled | |
| `taf.db.zalando.clone.backupBucket` | Zalando backup bucket; required when cloning is enabled | |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |

# Chart versions

| Chart version | taf version |
|---------------|-------------|
| 2.0.0         | 4.2.1       |
| 1.2.12        | 4.2.1       |
| 1.2.11        | 4.1.0       |
| 1.2.10        | 3.1.11      |
| 1.2.9         | 3.1.10      |
| 1.2.8         | 3.1.8       |
| 1.2.7         | 3.1.6       |
| 1.2.6         | 3.1.6       |
| 1.2.5         | 3.1.4       |
| 1.2.4         | 3.1.3       |
| 1.2.2         | 3.1.1       |
| 1.2.1         | 3.0.1       |
| 1.2.0         | 2.0.3       |
| 1.1.2         | 2.0.1       |
| 1.1.1         | 2.0.0       |
| 1.0.3         | 1.2.2       |
| 1.0.2         | 1.2.0       |
| 1.0.1         | 1.2.0       |
| 1.0.0         | 1.0.5       |
| 0.9.0         | 1.0.5       |
| 0.8.1         | 1.0.5       |
| 0.8.0         | 1.0.5       |
| 0.7.1         | 1.0.5       |
| 0.7.0         | 1.0.4       |
| 0.6.3         | 1.0.4       |
| 0.6.2         | 1.0.4       |
| 0.6.1         | 1.0.4       |
| 0.5.6         | 1.0.1       |
| 0.5.5         | 0.0.13      |
| 0.5.4         | 0.0.9       |
| 0.5.3         | 0.0.9       |
| 0.5.2         | 0.0.9       |
| 0.5.1         | 0.0.9       |
| 0.5.0         | 0.0.9       |
| 0.4.0         | 0.0.8       |
