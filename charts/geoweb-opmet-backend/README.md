# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
* Using aws as the secret provider
```yaml
opmet: 
  url: geoweb.example.com
  db_secret: secretName # Secret should contain postgresql database connection string
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret

secretProvider: aws
secretProviderParameters:
  region: your-region
```

* Using base64 encoded secret
```yaml
opmet:
  url: geoweb.example.com
  db_secret: base64_encoded_postgresql_connection_string
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-opmet-backend fmi/geoweb-opmet-backend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-opmet-backend fmi/geoweb-opmet-backend -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-opmet-backend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the Opmet backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.opmet` | Possibility to override application version | `v1.2.0` |
| `opmet.name` | Name of backend | `opmet` |
| `opmet.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend` |
| `opmet.commitHash` | Adds commitHash annotation to the deployment | |
| `opmet.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `opmet.url` | Url which the application can be accessed | |
| `opmet.path` | Path suffix added to url | `/opmet/(.*)` |
| `opmet.svcPort` | Port used for service | `80` |
| `opmet.replicas` | Amount of replicas deployed | `1` |
| `opmet.db_secret` | Secret containing base64 encoded Postgresql database connection string | |
| `opmet.db_secretName` | Name of db secret | `opmet-db` |
| `opmet.db_secretType` | Type to db secret | `secretsmanager` |
| `opmet.db_secretPath` | Path to db secret | |
| `opmet.db_secretKey` | Key of db secret | |
| `opmet.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `opmet.secretServiceAccount` | Service Account created for handling secrets | `opmet-service-account` |
| `opmet.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `opmet.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `opmet.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as opmet.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `opmet.env.BACKEND_OPMET_PORT_HTTP` | Port used for container | `8000` |
| `opmet.env.EXTERNALADDRESSES` | - | `0.0.0.0:80` |
| `opmet.env.MESSAGECONVERTER_URL` | - | `"http://localhost:8080"` |
| `opmet.env.OAUTH2_USERINFO` | - | `https://gitlab.com/oauth/userinfo` |
| `opmet.env.OPMET_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `opmet.env.FORWARDED_ALLOW_IPS` | - | `"*"` |
| `opmet.env.PUBLISHER_URL` | - | `"http://localhost:8090/publish"` |
| `opmet.messageconverter.name` | Name of messageconverter container | `opmet-messageconverter` |
| `opmet.messageconverter.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/avi-msgconverter/geoweb-knmi-avi-messageservices` |
| `opmet.messageconverter.version` | Possibility to override application version | `"0.1.1"` |
| `opmet.messageconverter.port` | Port used for messageconverter | `8080` |
| `opmet.messageconverter.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `opmet.messageconverter.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `opmet.messageconverter.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `opmet.nginx.name` | Name of nginx container | `opmet-nginx` |
| `opmet.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend/nginx-opmet-backend` |
| `opmet.nginx.OPMET_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `opmet.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | - |
| `opmet.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `opmet.nginx.EXTERNAL_HOSTNAME` | - | `localhost:80` |
| `opmet.nginx.OPMET_BACKEND_HOST` | Address where nginx accesses the backend | `localhost:8080` |
| `opmet.nginx.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `opmet.nginx.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `opmet.nginx.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `opmet.publisher.name` | Name of publisher container  | `opmet-publisher` |
| `opmet.publisher.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend/opmet-backend-publisher-local` |
| `opmet.publisher.port` | Port used for publisher | `8090`|
| `opmet.publisher.DESTINATION` | Folder inside publisher container where TACs are stored | `/app/output` |
| `opmet.publisher.volumeOptions` | yaml including the definition of the volume where TACs are published to, for example: <pre>hostPath:<br>&nbsp;&nbsp; path: /test/path</pre> or <pre>emptyDir:<br>&nbsp;&nbsp;</pre>| `emptyDir:` |
| `opmet.publisher.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `opmet.publisher.livenessProbe` | Configure libenessProbe | see defaults from `values.yaml` |
| `opmet.publisher.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |