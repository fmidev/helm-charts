# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create required dependencies

Create values.yaml file for required variables:
* Using aws as the secret provider
```yaml
warnings: 
  url: geoweb.example.com
  db_secret: secretName # Secret should contain postgresql database connection string
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret

secretProvider: aws
secretProviderParameters:
  region: your-region
```

* Using base64 encoded secret
```yaml
warnings:
  url: geoweb.example.com
  db_secret: base64_encoded_postgresql_connection_string
```

* Using custom configuration files stored locally
```yaml
warnings:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

* Using custom configuration files stored in AWS S3
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

* Using Zalando Operator Database
```yaml
warnings:
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
helm install geoweb-warnings-backend fmi/geoweb-warnings-backend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-warnings-backend fmi/geoweb-warnings-backend -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-warnings-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Warnings backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.warnings` | Possibility to override application version | |
| `warnings.name` | Name of backend | `warnings` |
| `warnings.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/warnings-backend` |
| `warnings.commitHash` | Adds commitHash annotation to the deployment | |
| `warnings.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `warnings.url` | Url which the application can be accessed | |
| `warnings.path` | Path suffix added to url | `/warnings/(.*)` |
| `warnings.svcPort` | Port used for service | `80` |
| `warnings.WARNINGS_PORT_HTTP` | Port used for container | `8080` |
| `warnings.replicas` | Amount of replicas deployed | `1` |
| `warnings.postStartCommand` | Command to run after warnings-backend is started | `bin/admin.sh` |
| `warnings.db_secret` | Secret containing base64 encoded Postgresql database connection string | |
| `warnings.db_secretName` | Name of db secret | `warnings-db` |
| `warnings.db_secretType` | Type to db secret | `secretsmanager` |
| `warnings.db_secretPath` | Path to db secret | |
| `warnings.db_secretKey` | Key of db secret | |
| `warnings.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `warnings.secretServiceAccount` | Service Account created for handling secrets | `warnings-service-account` |
| `warnings.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `warnings.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `warnings.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as warnings.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
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
| `warnings.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `warnings.nginx.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `warnings.nginx.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `warnings.db.enableDefaultDb` | Enable default postgres database | `true` |
| `warnings.db.name` | Default postgres database container name | `postgres` |
| `warnings.db.image` | Default postgres database image | `postgres` |
| `warnings.db.port` | Default postgres database port | `5432` |
| `warnings.db.POSTGRES_DB` | Default postgres database name | `warnings` |
| `warnings.db.POSTGRES_USER` | Default postgres database user | `postgres` |
| `warnings.db.POSTGRES_PASSWORD` | Default postgres database password | `postgres` |
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
| 0.6.3         | 0.12.0           |
| 0.6.0         | 0.11.0           |
| 0.5.2         | 0.11.0           |
| 0.5.1         | 0.9.2            |
| 0.5.0         | 0.6.3            |
| 0.4.1         | 0.6.3            |

