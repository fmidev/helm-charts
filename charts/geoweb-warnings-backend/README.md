# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

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
| `versions.warnings` | Possibility to override application version | `0.0.4` |
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
| `secretProvider` | Option to use secret provider instead of passing base64 encoded database connection string as warnings.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `warnings.nginx.name` | Name of nginx container | `nginx` |
| `warnings.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/warnings-backend/nginx-warnings-backend` |
| `warnings.nginx.WARNINGS_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `warnings.nginx.OAUTH2_USERINFO` | Userinfo endpoint to retrieve consented claims, or assertions, about the logged in end-user | - |
| `warnings.nginx.WARNINGS_BACKEND_HOST` | Address where nginx accesses the backend | `0.0.0.0:8080` |
| `warnings.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations if set | |