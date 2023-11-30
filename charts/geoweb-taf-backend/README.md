# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

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
  env:
    TAF_CONFIG: custom/config.ini
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

* Using custom configuration files stored in AWS S3
```yaml
taf:
  url: geoweb.example.com
  env:
    TAF_CONFIG: custom/config.ini
  useCustomConfigurationFiles: true
  customConfigurationLocation: s3
  s3bucketName: example-bucket
  customConfigurationFolderPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-taf-backend fmi/geoweb-taf-backend --dry-run --debug -n geoweb --values=./<yourvaluesfile>.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-taf-backend fmi/geoweb-taf-backend -n geoweb --values=./<yourvaluesfile>.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-taf-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Taf backend chart and their default values specified in file values.yaml.

| Parameter | Description | Default |
| - | - | - |
| `versions.taf` | Possibility to override application version | `v0.0.4` |
| `taf.name` | Name of backend | `taf` |
| `taf.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/aviation-taf-backend` |
| `taf.commitHash` | Adds commitHash annotation to the deployment | |
| `taf.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `taf.url` | Url which the application can be accessed | |
| `taf.path` | Path suffix added to url | `/taf/(.*)` |
| `taf.svcPort` | Port used for service | `80` |
| `taf.replicas` | Amount of replicas deployed | `1` |
| `taf.db_secret` | Secret containing base64 encoded Postgresql database connection string | |
| `taf.db_secretName` | Name of db secret | `taf-db` |
| `taf.db_secretType` | Type to db secret | `secretsmanager` |
| `taf.db_secretPath` | Path to db secret | |
| `taf.db_secretKey` | Key of db secret | |
| `taf.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `taf.secretServiceAccount` | Service Account created for handling secrets | `taf-service-account` |
| `taf.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `taf.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as taf.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `taf.env.AVIATION_TAF_PORT_HTTP` | Port used for container | `8000` |
| `taf.env.GEOWEB_KNMI_AVI_MESSAGESERVICES_HOST` | - | `"localhost:8081"` |
| `taf.env.AVIATION_TAF_PUBLISH_HOST` | - | `"localhost:8090"` |
| `taf.env.TAF_CONFIG` | Location of configuration file that is used | `config.ini` |
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
| `taf.messageconverter.version` | Possibility to override application version | `"0.1.1"` |
| `taf.messageconverter.port` | Port used for messageconverter | `8080` |
| `taf.messageconverter.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.messageconverter.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `taf.messageconverter.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `taf.nginx.name` | Name of nginx container | `taf-nginx` |
| `taf.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/nginx-aviation-taf-backend` |
| `taf.nginx.AVIATION_TAF_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `taf.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | |
| `taf.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `taf.nginx.NGINX_PORT_HTTPS` | Port used for nginx when SSL is enabled | `443` |
| `taf.nginx.AVIATION_TAF_BACKEND_HOST` | Address where nginx accesses the backend | `localhost:8080` |
| `taf.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.nginx.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `taf.nginx.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
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
| `taf.placeholder.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `taf.placeholder.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `taf.db.enableDefaultDb` | Enable default postgres database | `true` |
| `taf.db.name` | Default postgres database container name | `postgres` |
| `taf.db.image` | Default postgres database image | `postgres` |
| `taf.db.port` | Default postgres database port | `5432` |
| `taf.db.POSTGRES_DB` | Default postgres database name | `taf` |
| `taf.db.POSTGRES_USER` | Default postgres database user | `postgres` |
| `taf.db.POSTGRES_PASSWORD` | Default postgres database password | `postgres` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |