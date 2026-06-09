# GeoWeb Presets Backend Helm Chart

Deploys the GeoWeb presets backend, auth proxy sidecar, and optional PostgreSQL database resources.

# Upgrade notes for chart 3.0.0

Chart `3.0.0` introduces a breaking database values cleanup. The old `presets.db.enableDefaultDb` and `presets.db.useZalandoOperatorDb` booleans are replaced by the new `presets.db.mode` value, and database settings now live under common fields and mode-specific blocks. CloudNativePG support is new in this chart version.

Migration map:

| Removed value                                                                     | New value                                                                                                                                         |
| --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `presets.db.enableDefaultDb: true`                                                | `presets.db.mode: sidecar`                                                                                                                        |
| `presets.db.enableDefaultDb: false` with `presets.db.useZalandoOperatorDb: false` | `presets.db.mode: external`                                                                                                                       |
| `presets.db.useZalandoOperatorDb: true`                                           | `presets.db.mode: zalando`                                                                                                                        |
| `presets.db_secret`                                                               | `presets.db.external.encodedConnectionString` for inline base64, or `presets.db.external.secretProvider.objectName` for external secret providers |
| `presets.db_secretName`                                                           | `presets.db.external.secretName`                                                                                                                  |
| `presets.db_secretType`                                                           | `presets.db.external.secretProvider.objectType`                                                                                                   |
| `presets.db_secretPath`                                                           | `presets.db.external.secretProvider.path`                                                                                                         |
| `presets.db_secretKey`                                                            | `presets.db.external.secretProvider.key`                                                                                                          |
| `presets.iamRoleARN`                                                              | `presets.db.external.secretProvider.iamRoleARN`                                                                                                   |
| `secretProvider`                                                                  | `presets.db.external.secretProvider.provider`                                                                                                     |
| `secretProviderParameters`                                                        | `presets.db.external.secretProvider.parameters`                                                                                                   |
| `presets.db.POSTGRES_DB`                                                          | `presets.db.databaseName`                                                                                                                         |
| `presets.db.POSTGRES_USER`                                                        | `presets.db.username`                                                                                                                             |
| `presets.db.POSTGRES_PASSWORD`                                                    | `presets.db.sidecar.password` or `presets.db.cloudNativePG.bootstrap.password`                                                                    |
| `presets.db.POSTGRES_VERSION`                                                     | `presets.db.zalando.postgresVersion`                                                                                                              |
| `presets.db.numberOfInstances`                                                    | `presets.db.zalando.instances`                                                                                                                    |
| `presets.db.instanceSize`                                                         | `presets.db.zalando.volumeSize`                                                                                                                   |
| `presets.db.zalandoTeamId`                                                        | `presets.db.zalando.teamId`                                                                                                                       |
| `presets.db.enableLogicalBackup`                                                  | `presets.db.zalando.enableLogicalBackup`                                                                                                          |
| `presets.db.cleanInstall: false`                                                  | `presets.db.zalando.clone.enabled: true`                                                                                                          |
| `presets.db.backupTimestamp`                                                      | `presets.db.zalando.clone.timestamp`                                                                                                              |
| `presets.db.backupBucket`                                                         | `presets.db.zalando.clone.backupBucket`                                                                                                           |

For existing Zalando deployments, render old and migrated values before upgrading and compare the generated `postgresql` resource. The resource name, users, database name, team ID, instance count, and volume size should stay unchanged.

For existing external database deployments, verify that the rendered Deployment still reads `PRESETS_BACKEND_DB` from the intended Kubernetes Secret name and key.

# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create required dependencies

Create values.yaml file for required variables:

- Using an external database connection string from AWS Secrets Manager

```yaml
presets:
  url: geoweb.example.com
  db:
    mode: external
    external:
      secretName: presets-db
      secretKey: PRESETS_BACKEND_DB
      secretProvider:
        provider: aws
        className: presets-spc
        objectName: secretName # Secret should contain the PostgreSQL database connection string
        objectType: secretsmanager
        iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret
        parameters:
          region: your-region
```

- Using base64 encoded secret

```yaml
presets:
  url: geoweb.example.com
  db:
    mode: external
    external:
      secretName: presets-db
      secretKey: PRESETS_BACKEND_DB
      encodedConnectionString: base64_encoded_postgresql_connection_string
```

- Using custom configuration files stored locally

```yaml
presets:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

- Using custom configuration files stored in AWS S3

```yaml
presets:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationLocation: s3
  s3bucketName: example-bucket
  customConfigurationFolderPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

- Using custom presets stored locally

```yaml
presets:
  url: geoweb.example.com
  useCustomWorkspacePresets: true
  customPresetsPath: /example/path/
```

- Using custom presets stored in AWS S3

```yaml
presets:
  url: geoweb.example.com
  useCustomWorkspacePresets: true
  customWorkspacePresetLocation: s3
  customPresetsS3bucketName: example-bucket
  customPresetsPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

- Using Zalando Operator database

Database selection is controlled by `presets.db.mode`.

```yaml
presets:
  url: geoweb.example.com
  db:
    mode: zalando
    name: presets-db
    databaseName: presets
    username: geoweb
    zalando:
      clone:
        enabled: true
        backupBucket: s3://<S3-bucket-name>/
```

- Using CloudNativePG database

```yaml
presets:
  url: geoweb.example.com
  db:
    mode: cloudnativepg
    name: presets-db
    databaseName: presets
    username: geoweb
    cloudNativePG:
      instances: 1
      resources:
        requests:
          cpu: 100m
          memory: 256Mi
        limits:
          memory: 512Mi
      bootstrap:
        userSecretName: presets-db-user
        password: postgres
      storage:
        size: 1Gi
```

# Testing the Chart

Execute the following for testing the chart:

```bash
helm install geoweb-presets-backend fmi/geoweb-presets-backend --dry-run --debug --namespace geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-presets-backend fmi/geoweb-presets-backend --namespace geoweb --values=./values.yaml
```

# Deleting the Chart

Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-presets-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration

The following table lists the configurable parameters of the Presets backend chart and their default values.

| Parameter                                             | Description                                                                                                                                               | Default                                                                     |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `versions.presets`                                    | Possibility to override application version                                                                                                               |                                                                             |
| `presets.name`                                        | Name of backend                                                                                                                                           | `presets`                                                                   |
| `presets.registry`                                    | Registry to fetch image                                                                                                                                   | `registry.gitlab.com/opengeoweb/backend-services/presets-backend`           |
| `presets.commitHash`                                  | Adds commitHash annotation to the deployment                                                                                                              |                                                                             |
| `presets.imagePullPolicy`                             | Adds option to modify imagePullPolicy                                                                                                                     |                                                                             |
| `presets.url`                                         | Url which the application can be accessed                                                                                                                 |                                                                             |
| `presets.path`                                        | Path suffix added to url                                                                                                                                  | `/presets/(.*)`                                                             |
| `presets.svcPort`                                     | Port used for service                                                                                                                                     | `80`                                                                        |
| `presets.PRESETS_PORT_HTTP`                           | Port used for presets-backend container                                                                                                                   | `8080`                                                                      |
| `presets.replicas`                                    | Amount of replicas deployed                                                                                                                               | `1`                                                                         |
| `presets.minPodsAvailable`                            | Minimum available pods in pod disruption budget. Value `0` omits the pdb.                                                                                 | `0`                                                                         |
| `presets.DEPLOY_ENVIRONMENT`                          | Environment which presets should be seeded to the database                                                                                                | `open`                                                                      |
| `presets.postStartCommand`                            | Command to run after presets-backend is started                                                                                                           | `bin/admin.sh`                                                              |
| `presets.livenessProbe`                               | Configure main container livenessProbe                                                                                                                    | see defaults from `values.yaml`                                             |
| `presets.readinessProbe`                              | Configure main container readinessProbe                                                                                                                   | see defaults from `values.yaml`                                             |
| `presets.resources`                                   | Configure resource limits & requests                                                                                                                      | see defaults from `values.yaml`                                             |
| `presets.secretServiceAccount`                        | Service Account created for handling secrets                                                                                                              | `presets-service-account`                                                   |
| `presets.startupProbe`                                | Configure main container startupProbe                                                                                                                     | see defaults from `values.yaml`                                             |
| `presets.env.APPLICATION_ROOT_PATH`                   | Application root path for FastAPI. Generally same as `presets.path` without the wildcard.                                                                 | `/presets`                                                                  |
| `presets.nginx.name`                                  | Name of nginx container                                                                                                                                   | `nginx`                                                                     |
| `presets.nginx.registry`                              | Registry to fetch nginx image                                                                                                                             | `registry.gitlab.com/opengeoweb/backend-services/auth-backend/auth-backend` |
| `presets.nginx.version`                               | Possibility to override Nginx version                                                                                                                     | see default from `values.yaml`                                              |
| `presets.nginx.ENABLE_SSL`                            | Toggle SSL termination                                                                                                                                    | `"FALSE"`                                                                   |
| `presets.nginx.OAUTH2_USERINFO`                       | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user                                                               | -                                                                           |
| `presets.nginx.GEOWEB_USERNAME_CLAIM`                 | Claim name used as a user identifier in the presets-backend                                                                                               | `"email"`                                                                   |
| `presets.nginx.AUD_CLAIM`                             | Claim name used to get the token audience                                                                                                                 | `"aud"`                                                                     |
| `presets.nginx.AUD_CLAIM_VALUE`                       | Required value for the audience claim                                                                                                                     |                                                                             |
| `presets.nginx.ISS_CLAIM`                             | Issuer claim name used to get the token issuer                                                                                                            | `"iss"`                                                                     |
| `presets.nginx.ISS_CLAIM_VALUE`                       | Required value for the issuer claim                                                                                                                       |                                                                             |
| `presets.nginx.JWKS_URI`                              | JSON Web Key Set URI that points to an identity provider's public key set in JSON format                                                                  |                                                                             |
| `presets.nginx.GEOWEB_REQUIRE_READ_PERMISSION`        | Required OAUTH claim name and value to be present in the userinfo response for read operations                                                            | `"FALSE"`                                                                   |
| `presets.nginx.GEOWEB_REQUIRE_WRITE_PERMISSION`       | Required OAUTH claim name and value to be present in the userinfo response for write operations                                                           | `"FALSE"`                                                                   |
| `presets.nginx.ALLOW_ANONYMOUS_ACCESS`                | Allow/disallow anonymous access. Note that if an access token has been passed, it is checked even if anonymous access is allowed.                         | `"FALSE"`                                                                   |
| `presets.nginx.GEOWEB_ROLE_CLAIM_NAME`                | The name of the claim containing the security groups used with the roles                                                                                  | `"FALSE"`                                                                   |
| `presets.nginx.GEOWEB_ROLE_CLAIM_VALUE_PRESETS_ADMIN` | The name of the security group required to grant the preset-admin role                                                                                    | `"FALSE"`                                                                   |
| `presets.nginx.BACKEND_HOST`                          | Presets-backend container address where Nginx reverse proxy forwards the requests                                                                         | `0.0.0.0:8080`                                                              |
| `presets.nginx.NGINX_PORT_HTTP`                       | Port used for Nginx reverse proxy                                                                                                                         | `80`                                                                        |
| `presets.nginx.NGINX_PORT_HTTPS`                      | Port used for Nginx reverse proxy when SSL is enabled                                                                                                     | `443`                                                                       |
| `presets.nginx.livenessProbe`                         | Configure nginx container livenessProbe                                                                                                                   | see defaults from `values.yaml`                                             |
| `presets.nginx.readinessProbe`                        | Configure nginx container readinessProbe                                                                                                                  | see defaults from `values.yaml`                                             |
| `presets.nginx.resources`                             | Configure resource limits & requests                                                                                                                      | see defaults from `values.yaml`                                             |
| `presets.nginx.startupProbe`                          | Configure nginx container startupProbe                                                                                                                    | see defaults from `values.yaml`                                             |
| `presets.nginx.ENV_VAR_STRICT_MODE`                   | Enable check if all necessary variables for authentication and authorization are set                                                                      | `false`                                                                     |
| `presets.db.mode`                                     | Database mode _(sidecar\|external\|zalando\|cloudnativepg)_                                                                                               | `sidecar`                                                                   |
| `presets.db.name`                                     | Database resource/container name                                                                                                                          | `presets-db`                                                                |
| `presets.db.databaseName`                             | PostgreSQL database name                                                                                                                                  | `presets`                                                                   |
| `presets.db.username`                                 | PostgreSQL application user                                                                                                                               | `geoweb`                                                                    |
| `presets.db.sidecar.image`                            | Sidecar PostgreSQL image                                                                                                                                  | `postgres`                                                                  |
| `presets.db.sidecar.port`                             | Sidecar PostgreSQL port                                                                                                                                   | `5432`                                                                      |
| `presets.db.sidecar.password`                         | Sidecar PostgreSQL password                                                                                                                               | `postgres`                                                                  |
| `presets.db.external.secretName`                      | Kubernetes Secret name containing the external PostgreSQL connection string                                                                               | `presets-db`                                                                |
| `presets.db.external.secretKey`                       | Kubernetes Secret key containing the external PostgreSQL connection string                                                                                | `PRESETS_BACKEND_DB`                                                        |
| `presets.db.external.encodedConnectionString`         | Base64 encoded external PostgreSQL connection string used when no secret provider is configured                                                           | see default from `values.yaml`                                              |
| `presets.db.external.secretProvider.provider`         | External secret provider for database connection string _(aws\|azure\|gcp\|vault)_                                                                        |                                                                             |
| `presets.db.external.secretProvider.className`        | SecretProviderClass name for the database connection string                                                                                               | `presets-spc`                                                               |
| `presets.db.external.secretProvider.objectName`       | Provider object name containing the database connection string                                                                                            |                                                                             |
| `presets.db.external.secretProvider.objectType`       | Provider object type                                                                                                                                      | `secretsmanager`                                                            |
| `presets.db.external.secretProvider.path`             | Provider secret path for providers that require it                                                                                                        |                                                                             |
| `presets.db.external.secretProvider.key`              | Provider secret key for providers that require it                                                                                                         |                                                                             |
| `presets.db.external.secretProvider.iamRoleARN`       | IAM Role with permissions to access the external secret provider object                                                                                   |                                                                             |
| `presets.db.external.secretProvider.parameters`       | Extra parameters for the SecretProviderClass                                                                                                              | `{}`                                                                        |
| `presets.db.zalando.teamId`                           | Zalando Postgres operator team ID                                                                                                                         | `geoweb`                                                                    |
| `presets.db.zalando.postgresVersion`                  | Zalando Postgres version                                                                                                                                  | `15`                                                                        |
| `presets.db.zalando.instances`                        | Zalando Postgres instance count                                                                                                                           | `1`                                                                         |
| `presets.db.zalando.volumeSize`                       | Zalando Postgres data volume size                                                                                                                         | `100Mi`                                                                     |
| `presets.db.zalando.enableLogicalBackup`              | Enable Zalando logical backups                                                                                                                            | `true`                                                                      |
| `presets.db.zalando.clone.enabled`                    | Restore Zalando cluster from backup instead of clean install                                                                                              | `false`                                                                     |
| `presets.db.zalando.clone.timestamp`                  | Zalando clone timestamp                                                                                                                                   | `2030-01-01T00:00:00+00:00`                                                 |
| `presets.db.zalando.clone.backupBucket`               | Zalando clone backup bucket                                                                                                                               |                                                                             |
| `presets.db.cloudNativePG.bootstrap.userSecretName`   | CloudNativePG bootstrap user Secret name                                                                                                                  | `presets-db-user`                                                           |
| `presets.db.cloudNativePG.bootstrap.password`         | CloudNativePG bootstrap user password                                                                                                                     | `postgres`                                                                  |
| `presets.db.cloudNativePG.instances`                  | CloudNativePG instance count                                                                                                                              | `1`                                                                         |
| `presets.db.cloudNativePG.resources`                  | CloudNativePG container resources. Defaults set CPU and memory requests plus a memory limit, but no CPU limit.                                            | see defaults from `values.yaml`                                             |
| `presets.db.cloudNativePG.storage.size`               | CloudNativePG data volume size                                                                                                                            | `1Gi`                                                                       |
| `presets.db.cloudNativePG.storage.className`          | Optional CloudNativePG storage class                                                                                                                      |                                                                             |
| `presets.useCustomConfigurationFiles`                 | Use custom configurations                                                                                                                                 | `false`                                                                     |
| `presets.customConfigurationLocation`                 | Where custom configurations are located _(local\|s3)_                                                                                                     | `local`                                                                     |
| `presets.customConfigurationFolderPath`               | Path to the folder which contains custom configurations                                                                                                   |                                                                             |
| `presets.useCustomWorkspacePresets`                   | Use custom presets                                                                                                                                        | `false`                                                                     |
| `presets.customWorkspacePresetLocation`               | Where custom presets are located _(local\|s3)_                                                                                                            | `local`                                                                     |
| `presets.customPresetsPath`                           | Path to the folder which contains custom presets                                                                                                          |                                                                             |
| `presets.customPresetsS3bucketName`                   | Name of the S3 bucket where custom presets are stored                                                                                                     |                                                                             |
| `presets.volumeAccessMode`                            | Permissions of the application for the custom configurations and custom presets PersistentVolume used                                                     | `ReadOnlyMany`                                                              |
| `presets.volumeSize`                                  | Size of the custom configuration and presets PersistentVolume                                                                                             | `100Mi`                                                                     |
| `presets.awsAccessKeyId`                              | AWS_ACCESS_KEY_ID for authenticating to S3                                                                                                                |                                                                             |
| `presets.awsAccessKeySecret`                          | AWS_SECRET_ACCESS_KEY for authenticating to S3                                                                                                            |                                                                             |
| `presets.awsDefaultRegion`                            | Region where your S3 bucket is located                                                                                                                    |                                                                             |
| `ingress.name`                                        | Name of the ingress controller in use                                                                                                                     | `nginx-ingress-controller`                                                  |
| `ingress.tls`                                         | TLS configuration section for the ingress                                                                                                                 |                                                                             |
| `ingress.ingressClassName`                            | Set ingressClassName parameter to not use default ingressClass                                                                                            | `nginx`                                                                     |
| `ingress.customAnnotations`                           | Custom annotations for ingress, for example <pre>customAnnotations:<br> traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set |                                                                             |

# Chart versions

| Chart version | presets version |
| ------------- | --------------- |
| 3.0.0         | 4.1.2           |
| 2.15.13       | 4.1.2           |
| 2.15.12       | 4.1.0           |
| 2.15.11       | 4.0.0           |
| 2.15.10       | 3.37.2          |
| 2.15.9        | 3.37.0          |
| 2.15.8        | 3.36.0          |
| 2.15.7        | 3.34.1          |
| 2.15.6        | 3.32.1          |
| 2.15.4        | 3.32.0          |
| 2.15.3        | 3.31.0          |
| 2.15.2        | 3.30.0          |
| 2.15.1        | 3.27.7          |
| 2.15.0        | 3.27.4          |
| 2.14.10       | 3.27.4          |
| 2.14.9        | 3.27.3          |
| 2.14.8        | 3.27.1          |
| 2.14.7        | 3.26.0          |
| 2.14.6        | 3.26.0          |
| 2.14.5        | 3.26.0          |
| 2.14.4        | 3.24.1          |
| 2.14.3        | 3.23.0          |
| 2.14.2        | 3.23.0          |
| 2.14.1        | 3.22.2          |
| 2.14.0        | 3.21.1          |
| 2.13.0        | 3.21.1          |
| 2.12.5        | 3.21.1          |
| 2.12.4        | 3.19.1          |
| 2.12.3        | 3.19.0          |
| 2.12.2        | 3.19.0          |
| 2.12.1        | 3.19.0          |
| 2.11.3        | 3.16.1          |
| 2.11.2        | 3.16.1          |
| 2.11.1        | 3.12.0          |
| 2.11.0        | 3.12.0          |
| 2.10.1        | 3.11.1          |
| 2.10.0        | 3.11.0          |
