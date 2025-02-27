# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
* Using aws as the secret provider
```yaml
presets: 
  url: geoweb.example.com
  db_secret: secretName # Secret should contain postgresql database connection string
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret

secretProvider: aws
secretProviderParameters:
  region: your-region
```

* Using base64 encoded secret
```yaml
presets:
  url: geoweb.example.com
  db_secret: base64_encoded_postgresql_connection_string
```

* Using custom configuration files stored locally
```yaml
presets:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

* Using custom configuration files stored in AWS S3
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

* Using custom presets stored locally
```yaml
presets:
  url: geoweb.example.com
  useCustomWorkspacePresets: true
  customPresetsPath: /example/path/
```

* Using custom presets stored in AWS S3
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

* Using Zalando Operator Database
```yaml
presets:
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

| Parameter | Description | Default |
| - | - | - |
| `versions.presets` | Possibility to override application version | |
| `presets.name` | Name of backend | `presets` |
| `presets.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/presets-backend` |
| `presets.commitHash` | Adds commitHash annotation to the deployment | |
| `presets.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `presets.url` | Url which the application can be accessed | |
| `presets.path` | Path suffix added to url | `/presets/(.*)` |
| `presets.svcPort` | Port used for service | `80` |
| `presets.PRESETS_PORT_HTTP` | Port used for presets-backend container | `8080` |
| `presets.replicas` | Amount of replicas deployed | `1` |
| `presets.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` | 
| `presets.DEPLOY_ENVIRONMENT` | Environment which presets should be seeded to the database  | `open` |
| `presets.postStartCommand` | Command to run after presets-backend is started | `bin/admin.sh` |
| `presets.db_secret` | Secret containing base64 encoded Postgresql database connection string | |
| `presets.db_secretName` | Name of db secret | `presets-db` |
| `presets.db_secretType` | Type to db secret | `secretsmanager` |
| `presets.db_secretPath` | Path to db secret | |
| `presets.db_secretKey` | Key of db secret | |
| `presets.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `presets.livenessProbe` | Configure main container livenessProbe | see defaults from `values.yaml` |
| `presets.readinessProbe` | Configure main container readinessProbe | see defaults from `values.yaml` |
| `presets.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `presets.secretServiceAccount` | Service Account created for handling secrets | `presets-service-account` |
| `presets.startupProbe` | Configure main container startupProbe | see defaults from `values.yaml` |
| `presets.env.APPLICATION_ROOT_PATH` | Application root path for FastAPI. Generally same as `presets.path` without the wildcard. | `/presets` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as presets.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `presets.nginx.name` | Name of nginx container | `nginx` |
| `presets.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/auth-backend/auth-backend` |
| `presets.nginx.version` | Possibility to override Nginx version | see default from `values.yaml` |
| `presets.nginx.ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `presets.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | - |
| `presets.nginx.GEOWEB_USERNAME_CLAIM` | Claim name used as a user identifier in the presets-backend | `"email"` |
| `presets.nginx.AUD_CLAIM` | Claim name used to get the token audience | `"aud"` |
| `presets.nginx.AUD_CLAIM_VALUE` | Required value for the audience claim | |
| `presets.nginx.ISS_CLAIM` | Issuer claim name used to get the token issuer | `"iss"` |
| `presets.nginx.ISS_CLAIM_VALUE` | Required value for the issuer claim | |
| `presets.nginx.JWKS_URI` | JSON Web Key Set URI that points to an identity provider's public key set in JSON format | |
| `presets.nginx.GEOWEB_REQUIRE_READ_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for read operations | `"FALSE"` |
| `presets.nginx.GEOWEB_REQUIRE_WRITE_PERMISSION` | Required OAUTH claim name and value to be present in the userinfo response for write operations | `"FALSE"` |
| `presets.nginx.ALLOW_ANONYMOUS_ACCESS` | Allow/disallow anonymous access. Note that if an access token has been passed, it is checked even if anonymous access is allowed. | `"FALSE"` |
| `presets.nginx.GEOWEB_ROLE_CLAIM_NAME` | The name of the claim containing the security groups used with the roles | `"FALSE"` |
| `presets.nginx.GEOWEB_ROLE_CLAIM_VALUE_PRESETS_ADMIN` | The name of the security group required to grant the preset-admin role | `"FALSE"` |
| `presets.nginx.BACKEND_HOST` | Presets-backend container address where Nginx reverse proxy forwards the requests | `0.0.0.0:8080` |
| `presets.nginx.NGINX_PORT_HTTP` | Port used for Nginx reverse proxy| `80` |
| `presets.nginx.NGINX_PORT_HTTPS` | Port used for Nginx reverse proxy when SSL is enabled | `443` |
| `presets.nginx.livenessProbe` | Configure nginx container livenessProbe | see defaults from `values.yaml` |
| `presets.nginx.readinessProbe` | Configure nginx container readinessProbe | see defaults from `values.yaml` |
| `presets.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `presets.nginx.startupProbe` | Configure nginx container startupProbe | see defaults from `values.yaml` |
| `presets.db.enableDefaultDb` | Enable default postgres database | `true` |
| `presets.db.name` | Default postgres database container name | `postgres` |
| `presets.db.image` | Default postgres database image | `postgres` |
| `presets.db.port` | Default postgres database port | `5432` |
| `presets.db.POSTGRES_DB` | Default postgres database name | `presets` |
| `presets.db.POSTGRES_USER` | Default postgres database user | `postgres` |
| `presets.db.POSTGRES_PASSWORD` | Default postgres database password | `postgres` |
| `presets.useCustomConfigurationFiles` | Use custom configurations | `false` |
| `presets.customConfigurationLocation` | Where custom configurations are located *(local\|s3)* | `local` |
| `presets.customConfigurationFolderPath` | Path to the folder which contains custom configurations | |
| `presets.useCustomWorkspacePresets` | Use custom presets | `false` |
| `presets.customWorkspacePresetLocation` | Where custom presets are located *(local\|s3)* | `local` |
| `presets.customPresetsPath` | Path to the folder which contains custom presets | |
| `presets.customPresetsS3bucketName` | Name of the S3 bucket where custom presets are stored | |
| `presets.volumeAccessMode` | Permissions of the application for the custom configurations and custom presets PersistentVolume used | `ReadOnlyMany` |
| `presets.volumeSize` | Size of the custom configuration and presets PersistentVolume | `100Mi` |
| `presets.awsAccessKeyId` | AWS_ACCESS_KEY_ID for authenticating to S3 | |
| `presets.awsAccessKeySecret` | AWS_SECRET_ACCESS_KEY for authenticating to S3 | |
| `presets.awsDefaultRegion` | Region where your S3 bucket is located | |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |

# Chart versions

| Chart version | presets version |
|---------------|-----------------|
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
