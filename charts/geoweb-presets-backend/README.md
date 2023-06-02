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
  s3bucketName: example-bucket
  customPresetsPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-presets-backend fmi/geoweb-presets-backend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-presets-backend fmi/geoweb-presets-backend -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-presets-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Presets backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.presets` | Possibility to override application version | `3.1.0` |
| `presets.name` | Name of backend | `presets` |
| `presets.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/presets-backend` |
| `presets.commitHash` | Adds commitHash annotation to the deployment | |
| `presets.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `presets.url` | Url which the application can be accessed | |
| `presets.path` | Path suffix added to url | `/presets/(.*)` |
| `presets.svcPort` | Port used for service | `80` |
| `presets.PRESETS_PORT_HTTP` | Port used for container | `8080` |
| `presets.replicas` | Amount of replicas deployed | `1` |
| `presets.EXTERNALADDRESSES` | - | `0.0.0.0:80` |
| `presets.DEPLOY_ENVIRONMENT` | Environment which presets should be seeded to the database  | `open` |
| `presets.postStartCommand` | Command to run after presets-backend is started | `bin/admin.sh` |
| `presets.db_secret` | Secret containing base64 encoded Postgresql database connection string | |
| `presets.db_secretName` | Name of db secret | `presets-db` |
| `presets.db_secretType` | Type to db secret | `secretsmanager` |
| `presets.db_secretPath` | Path to db secret | |
| `presets.db_secretKey` | Key of db secret | |
| `presets.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `presets.secretServiceAccount` | Service Account created for handling secrets | `presets-service-account` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as presets.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `presets.nginx.name` | Name of nginx container | `nginx` |
| `presets.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/presets-backend/nginx-presets-backend` |
| `presets.nginx.PRESETS_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `presets.nginx.OAUTH2_USERINFO` | - | `https://gitlab.com/oauth/userinfo` |
| `presets.nginx.PRESETS_BACKEND_HOST` | Address where nginx accesses the backend | `0.0.0.0:8080` |
| `presets.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `presets.useCustomWorkspacePresets` | Use custom presets | `false` |
| `presets.customWorkspacePresetLocation` | Where custom presets are located *(local\|s3)* | `local` |
| `presets.volumeAccessMode` | Permissions of the application for the custom presets PersistentVolume used | `ReadOnlyMany` |
| `presets.volumeSize` | Size of the custom presets PersistentVolume | `100Mi` |
| `presets.customPresetsPath` | Path to the folder which contains custom presets | |
| `presets.s3bucketName` | Name of the S3 bucket where custom presets are stored | |
| `presets.awsAccessKeyId` | AWS_ACCESS_KEY_ID for authenticating to S3 | |
| `presets.awsAccessKeySecret` | AWS_SECRET_ACCESS_KEY for authenticating to S3 | |
| `presets.awsDefaultRegion` | Region where your S3 bucket is located | |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |