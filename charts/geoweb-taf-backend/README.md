# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create required dependencies

Create your own values file for required variables:
* Using aws as the secret provider
```yaml
taf: 
  url: geoweb.example.com
  db_secret: secretName # Secret should contain postgresql database connection string
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret

secretProvider: aws
secretProviderParameters:
  region: your-region
```

* Using base64 encoded secret
```yaml
taf:
  url: geoweb.example.com
  db_secret: base64_encoded_postgresql_connection_string
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
    enableDefaultDb: false
    useZalandoOperatorDb: true
    cleanInstall: false # Add this line only after first install
    backupBucket: s3://<S3-bucket-name>/
```

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
| `taf.db_secret` | Secret containing base64 encoded Postgresql database connection string | |
| `taf.db_secretName` | Name of db secret | `taf-db` |
| `taf.db_secretType` | Type to db secret | `secretsmanager` |
| `taf.db_secretPath` | Path to db secret | |
| `taf.db_secretKey` | Key of db secret | |
| `taf.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `taf.secretServiceAccount` | Service Account created for handling secrets | `taf-service-account` |
| `taf.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.startupProbe` | Configure main container startupProbe | see defaults from `values.yaml` |
| `taf.livenessProbe` | Configure main container livenessProbe | see defaults from `values.yaml` |
| `taf.readinessProbe` | Configure main container readinessProbe | see defaults from `values.yaml` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as taf.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
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
| `taf.messageconverter.port` | Port used for messageconverter | `8080` |
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
| `taf.nginx.BACKEND_HOST` | Taf-backend container address where Nginx reverse proxy forwards the requests | `0.0.0.0:8080` |
| `taf.nginx.NGINX_PORT_HTTP` | Port used for Nginx reverse proxy | `80` |
| `taf.nginx.NGINX_PORT_HTTPS` | Port used for Nginx reverse proxy when SSL is enabled | `443` |
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
| `taf.publisher.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `taf.publisher.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `taf.placeholder.name` | Name of publisher container  | `taf-placeholder` |
| `taf.placeholder.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/tafplaceholder-aviation-taf-backend` |
| `taf.placeholder.TAFPLACEHOLDER_KEEPRUNNING` | - | `TRUE` |
| `taf.placeholder.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.placeholder.startupProbe` | Configure placeholder container startupProbe | see defaults from `values.yaml` |
| `taf.placeholder.livenessProbe` | Configure placeholder container livenessProbe | see defaults from `values.yaml` |
| `taf.placeholder.readinessProbe` | Configure placeholder container readinessProbe | see defaults from `values.yaml` |
| `taf.db.enableDefaultDb` | Enable default postgres database | `true` |
| `taf.db.name` | Default postgres database container name | `postgres` |
| `taf.db.image` | Default postgres database image | `postgres` |
| `taf.db.port` | Default postgres database port | `5432` |
| `taf.db.POSTGRES_DB` | Default postgres database name | `taf` |
| `taf.db.POSTGRES_USER` | Default postgres database user | `postgres` |
| `taf.db.POSTGRES_PASSWORD` | Default postgres database password | `postgres` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |

# Chart versions

| Chart version | taf version |
|---------------|-------------|
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
