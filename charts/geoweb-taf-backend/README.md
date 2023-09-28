# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
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

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-taf-backend fmi/geoweb-taf-backend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-taf-backend fmi/geoweb-taf-backend -n geoweb --values=./values.yaml
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
The following table lists the configurable parameters of the Taf backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.taf` | Possibility to override application version | `v0.0.1` |
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
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as taf.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `taf.env.AVIATION_TAF_PORT_HTTP` | Port used for container | `8000` |
| `taf.env.GEOWEB_KNMI_AVI_MESSAGESERVICES_HOST` | - | `"localhost:8081"` |
| `taf.env.OAUTH2_USERINFO` | - | |
| `taf.env.AVIATION_TAF_PUBLISH_HOST` | - | `"localhost:8090"` |
| `taf.messageconverter.name` | Name of messageconverter container | `taf-messageconverter` |
| `taf.messageconverter.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/avi-msgconverter/geoweb-knmi-avi-messageservices` |
| `taf.messageconverter.version` | Possibility to override application version | `"0.1.1"` |
| `taf.messageconverter.port` | Port used for messageconverter | `8080` |
| `taf.messageconverter.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.nginx.name` | Name of nginx container | `taf-nginx` |
| `taf.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/nginx-aviation-taf-backend` |
| `taf.nginx.AVIATION_TAF_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `taf.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | |
| `taf.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `taf.nginx.EXTERNAL_HOSTNAME` | - | `localhost:80` |
| `taf.nginx.AVIATION_TAF_BACKEND_HOST` | Address where nginx accesses the backend | `localhost:8080` |
| `taf.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.publisher.name` | Name of publisher container  | `taf-publisher` |
| `taf.publisher.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/aviation-taf-backend-publisher-local` |
| `taf.publisher.port` | Port used for publisher | `8090`|
| `taf.publisher.DESTINATION` | Folder inside publisher container where TACs are stored | `/app/output` |
| `taf.publisher.volumeOptions` | yaml including the definition of the volume where TACs are published to, for example: <pre>hostPath:<br>&nbsp;&nbsp; path: /test/path</pre> or <pre>emptyDir:<br>&nbsp;&nbsp;</pre>| `emptyDir:` |
| `taf.publisher.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `taf.placeholder.name` | Name of publisher container  | `taf-placeholder` |
| `taf.placeholder.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/aviation-taf-backend/tafplaceholder-aviation-taf-backend` |
| `taf.placeholder.port` | Port used for tafplaceholder | `8085` |
| `taf.placeholder.TAFPLACEHOLDER_KEEPRUNNING` | - | `TRUE` |
| `taf.placeholder.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |