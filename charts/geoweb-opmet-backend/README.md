# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create required dependencies

Create values.yaml file for required variables:
* Using AWS as the secret provider (use any mix of db_secret, ssh_secret and ssh_secret_passphrase)
```yaml
opmet: 
  url: geoweb.example.com
  db_secret: secretName
  ssh_secrets:
  - name: key_secret_name_in_kubernetes
    secret: secret_name_in_AWS
    type: secretsmanager
  ssh_secret_passphrases:
  - name: passphrase_secret_name_in_kubernetes
    secret: secret_name_in_AWS
    type: secretsmanager
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret

secretProvider: aws
secretProviderParameters:
  region: your-region
```

* Using base64 encoded secret (use any mix of db_secret, ssh_secret and ssh_secret_passphrase)
```yaml
opmet:
  url: geoweb.example.com
  db_secret: base64_encoded_postgresql_connection_string
  ssh_secret:
  - name: key_secret_name_in_kubernetes
    secret: base64_encoded_ssh_private_key
  ssh_secret_passphrase:
  - name: passphrase_secret_name_in_kubernetes
    secret: base64_encoded_ssh_private_key_passphrase
```

* Using custom configuration files stored locally
```yaml
opmet:
  env:
    BACKEND_CONFIG: configuration_files/custom/backendConfig.json
    SIGMET_CONFIG: configuration_files/custom/sigmetConfig.json
    AIRMET_CONFIG: configuration_files/custom/airmetConfig.json
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

* Using custom configuration files stored in AWS S3
```yaml
opmet:
  url: geoweb.example.com
  env:
    BACKEND_CONFIG: configuration_files/custom/backendConfig.json
    SIGMET_CONFIG: configuration_files/custom/sigmetConfig.json
    AIRMET_CONFIG: configuration_files/custom/airmetConfig.json
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
opmet:
  url: geoweb.example.com
  db:
    enableDefaultDb: false
    useZalandoOperatorDb: true
    cleanInstall: false # Add this line only after first install
    backupBucket: s3://<S3-bucket-name>/
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-opmet-backend fmi/geoweb-opmet-backend --dry-run --debug --namespace geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-opmet-backend fmi/geoweb-opmet-backend --namespace geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-opmet-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
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
| `opmet.db.backupBucket`                       | AWS S3 bucket used to fetch database backup |                                                                                              |
| `opmet.db.backupTimestamp`                    | Timestamp to fetch database backup from (latest backup before configured timestamp) | `"2030-01-01T00:00:00+00:00"`                                                                |
| `opmet.db.cleanInstall`                       | Create a clean Zalando postgres database (turning `false` will enable cloning startup state from backup, database won't start if no backup found) | `true`                                                                                       |
| `opmet.db.enableDefaultDb`                    | Enable default postgres database | `true`                                                                                       |
| `opmet.db.enableLogicalBackup`                | Enable logical backup for Zalando postgres databases (SQL commands with pg_dump) | `true`                                                                                       |
| `opmet.db.image`                              | Default postgres database image | `postgres`                                                                                   |
| `opmet.db.instanceSize`                       | Size of the volumes used by Zalando postgres database instances | `100Mi`                                                                                      |
| `opmet.db.name`                               | Default postgres database container/Zalando postgres database pod name | `opmet-db`                                                                                   |
| `opmet.db.numberOfInstances`                  | Number of Zalando postgres database instances created | `1`                                                                                          |
| `opmet.db.port`                               | Default postgres database port | `5432`                                                                                       |
| `opmet.db.POSTGRES_DB`                        | Default/Zalando postgres database name | `opmet`                                                                                      |
| `opmet.db.POSTGRES_PASSWORD`                  | Default postgres database password | `postgres`                                                                                   |
| `opmet.db.POSTGRES_USER`                      | Default/Zalando postgres database user | `geoweb`                                                                                     |
| `opmet.db.POSTGRES_VERSION`                   | Postgres version used by Zalando Postgres database | `15`                                                                                         |
| `opmet.db.useZalandoOperatorDb`               | Enable postgres database with Zalando Postgres Operator | `false`                                                                                      |
| `opmet.db.zalandoTeamId`                      | Team id of Zalando databases  | `geoweb`                                                                                     |
| `opmet.db_secret`                             | Secret containing base64 encoded Postgresql database connection string |                                                                                              |
| `opmet.db_secretKey`                          | Key of db secret (only vault) |                                                                                              |
| `opmet.db_secretName`                         | Name of db secret | `opmet-db`                                                                                   |
| `opmet.db_secretPath`                         | Path to db secret (only gcp and vault) |                                                                                              |
| `opmet.db_secretType`                         | Type to db secret (only aws + azure) | `secretsmanager`                                                                             |
| `opmet.env.AIRMET_CONFIG`                     | Location of AIRMET configuration file that is used (application defaults to `configuration_files/airmetConfig.json`) |                                                                                              |
| `opmet.env.BACKEND_CONFIG`                    | Location of backend configuration file that is used (application defaults to `configuration_files/backendConfig.json`) |                                                                                              |
| `opmet.env.BACKEND_OPMET_PORT_HTTP`           | Port used for container | `8000`                                                                                       |
| `opmet.env.MESSAGECONVERTER_URL`              | - | `"http://localhost:8080"`                                                                    |
| `opmet.env.PUBLISHER_URL`                     | - | `"http://localhost:8090/publish"`                                                            |
| `opmet.env.SIGMET_CONFIG`                     | Location of SIGMET configuration file that is used (application defaults to `configuration_files/sigmetConfig.json`) |                                                                                              |
| `opmet.iamRoleARN`                            | IAM Role with permissions to access secrets |                                                                                              |
| `opmet.imagePullPolicy`                       | Adds option to modify imagePullPolicy |                                                                                              |
| `opmet.livenessProbe`                         | Configure libenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.messageconverter.livenessProbe`        | Configure libenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.messageconverter.name`                 | Name of messageconverter container | `opmet-messageconverter`                                                                     |
| `opmet.messageconverter.port`                 | Port used for messageconverter | `8080`                                                                                       |
| `opmet.messageconverter.readinessProbe`       | Configure readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.messageconverter.registry`             | Registry to fetch image | `registry.gitlab.com/opengeoweb/avi-msgconverter/geoweb-knmi-avi-messageservices`            |
| `opmet.messageconverter.resources`            | Configure resource limits & requests | see defaults from `values.yaml`                                                              |
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
| `opmet.nginx.GEOWEB_USERNAME_CLAIM`           | Claim name used as a user identifier in the presets-backend | `"email"`|
| `opmet.nginx.ISS_CLAIM`                       | Issuer claim name used to get the token issuer | `"iss"` |
| `opmet.nginx.ISS_CLAIM_VALUE`                 | Required value for the issuer claim |  |
| `opmet.nginx.JWKS_URI`                        | JSON Web Key Set URI that points to an identity provider's public key set in JSON format |  |
| `opmet.nginx.livenessProbe`                   | Configure libenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.nginx.name`                            | Name of nginx container | `opmet-nginx`                                                                                |
| `opmet.nginx.NGINX_PORT_HTTP`                 | Port used for nginx | `80`                                                                                         |
| `opmet.nginx.NGINX_PORT_HTTPS`                | Port used for nginx when SSL is enabled | `443`                                                                                        |
| `opmet.nginx.OAUTH2_USERINFO`                 | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | |
| `opmet.nginx.readinessProbe`                  | Configure readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.nginx.registry`                        | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/auth-backend/auth-backend`          |
| `opmet.nginx.resources`                       | Configure resource limits & requests | see defaults from `values.yaml`|
| `opmet.nginx.version`                         | Possibility to override Nginx version | see default from `values.yaml` |
| `opmet.path`                                  | Path suffix added to url | `/opmet/(.*)`                                                                                |
| `opmet.publisher.DESTINATION`                 | Folder inside publisher container where TACs are stored (used with local-publisher) | `/app/output`                                                                                |
| `opmet.publisher.livenessProbe`               | Configure libenessProbe | see defaults from `values.yaml`                                                              |
| `opmet.publisher.name`                        | Name of publisher container  | `opmet-publisher`                                                                            |
| `opmet.publisher.port`                        | Port used for publisher | `8090`                                                                                       |
| `opmet.publisher.readinessProbe`              | Configure readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.publisher.registry`                    | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend/opmet-backend-publisher-local` |
| `opmet.publisher.resources`                   | Configure resource limits & requests | see defaults from `values.yaml`                                                              |
| `opmet.publisher.S3_BUCKET_NAME`              | S3 Bucket used to publish files to |                                                                                              |
| `opmet.publisher.SERVERS`                     | List of configuration options used to access SFTP server. List of jsons. Note that ssh secrets get mounted to `/mnt/secrets-store`. Details https://gitlab.com/opengeoweb/backend-services/opmet-backend#sftp-publisher |                                                                                              |
| `opmet.publisher.version`                     | Publisher version | defaults to Chart.AppVersion                                                                 |
| `opmet.publisher.volumeOptions`               | yaml including the definition of the volume where TACs are published to, for example: <pre>hostPath:<br>&nbsp;&nbsp; path: /test/path</pre> or <pre>emptyDir:<br>&nbsp;&nbsp;</pre>| `emptyDir:`                                                                                  |
| `opmet.readinessProbe`                        | Configure readinessProbe | see defaults from `values.yaml`                                                              |
| `opmet.registry`                              | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend`                              |
| `opmet.replicas`                              | Amount of replicas deployed | `1`                                                                                          |
| `opmet.resources`                             | Configure resource limits & requests | see defaults from `values.yaml`                                                              |
| `opmet.s3bucketName`                          | Name of the S3 bucket where custom configurations are stored |                                                                                              |
| `opmet.secretServiceAccount`                  | Service Account created for handling secrets | `opmet-service-account`                                                                      |
| `opmet.ssh_passphrase_secrets`                | Map to configure which ssh private key passphrase secrets you want with multiples supported, map can use values of `secret`, `name`, `type` (only aws + azure), `path` (only gcp and vault) and `key` (only vault) |                                                                                              |
| `opmet.ssh_secrets`                           | Map to configure which ssh private key secrets you want with multiples supported, map can use values of `secret`, `name`, `type` (only aws + azure), `path` (only gcp and vault) and `key` (only vault) |                                                                                              |
| `opmet.svcPort`                               | Port used for service | `80`                                                                                         |
| `opmet.url`                                   | Url which the application can be accessed |                                                                                              |
| `opmet.useCustomConfigurationFiles`           | Use custom configurations | `false`                                                                                      |
| `opmet.volumeAccessMode`                      | Permissions of the application for the custom configurations PersistentVolume used | `ReadOnlyMany`                                                                               |
| `opmet.volumeSize`                            | Size of the custom configurations PersistentVolume | `100Mi`                                                                                      |
| `secretProvider`                              | Option to use secret provider instead of passing base64 encoded database connection string as opmet.db_secret *(aws\|azure\|gcp\|vault)* |                                                                                              |
| `secretProviderParameters`                    | Option to add custom parameters to the secretProvider, for example with aws you can specify region |                                                                                              |
| `versions.opmet`                              | Possibility to override application version |                                                                                              |

# Chart versions

| Chart version | opmet version |
|---------------|---------------|
| 3.5.1         | 3.0.0         |
| 3.4.4         | 2.12.1        |
| 3.4.3         | 2.11.0        |
| 3.4.2         | 2.10.1        |
| 3.4.1         | 2.9.2         |
| 3.4.0         | 2.9.1         |
| 3.2.0         | 2.7.0         |
