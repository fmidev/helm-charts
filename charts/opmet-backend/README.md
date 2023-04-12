# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
opmet:
  url: geoweb.example.com
  db_secret: secretName # Secret should contain postgresql database connection string
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret
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
| `versions.opmet` | Possibility to override application version | `v0.0.1` |
| `opmet.name` | Name of backend | `opmet` |
| `opmet.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend` |
| `opmet.commitHash` | Adds commitHash annotation to the deployment | |
| `opmet.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `opmet.url` | Url which the application can be accessed | |
| `opmet.path` | Path suffix added to url | `/opmet/(.*)` |
| `opmet.svcPort` | Port used for service | `80` |
| `opmet.replicas` | Amount of replicas deployed | `1` |
| `opmet.db_secret` | Secret containing Postgresql database connection string | |
| `opmet.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `opmet.env.BACKEND_OPMET_PORT_HTTP` | Port used for container | `8000` |
| `opmet.env.EXTERNALADDRESSES` | - | `0.0.0.0:80` |
| `opmet.env.ENV_STATE` | - | `TEST` |
| `opmet.env.TEST_MESSAGECONVERTER_URL` | - | `"http://localhost:8080/getsigmettac"` |
| `opmet.env.TEST_TEST_FIELD` | - | `"A"` |
| `opmet.env.TEST_MWO_CCCC` | - | `"EHDB"` |
| `opmet.env.TEST_SIGMET_HEADER__VA_CLD` | - | `"WVNL31"` |
| `opmet.env.TEST_SIGMET_HEADER__TC` | - | `"WCNL31"` |
| `opmet.env.TEST_SIGMET_HEADER__DEFAULT` | - | `"WSNL31"` |
| `opmet.env.TEST_IWXXM_SIGMET_HEADER__VA_CLD` | - | `"LVNL31"` |
| `opmet.env.TEST_IWXXM_SIGMET_HEADER__TC` | - | `"LYNL31"` |
| `opmet.env.TEST_IWXXM_SIGMET_HEADER__DEFAULT` | - | `"LSNL31"` |
| `opmet.env.OAUTH2_USERINFO` | - | `https://gitlab.com/oauth/userinfo` |
| `opmet.env.OPMET_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `opmet.env.FORWARDED_ALLOW_IPS` | - | `"*"` |
| `opmet.messageconverter.name` | Name of messageconverter container | `opmet-messageconverter` |
| `opmet.messageconverter.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/avi-msgconverter/geoweb-knmi-avi-messageservices` |
| `opmet.messageconverter.version` | Possibility to override application version | `"0.1.1"` |
| `opmet.messageconverter.port` | Port used for messageconverter | `8080` |
| `opmet.nginx.name` | Name of nginx container | `opmet-nginx` |
| `opmet.nginx.registry` | Registry to fetch nginx image | `registry.gitlab.com/opengeoweb/backend-services/opmet-backend/nginx-opmet-backend` |
| `opmet.nginx.OPMET_ENABLE_SSL` | Toggle SSL termination | `"FALSE"` |
| `opmet.nginx.OAUTH2_USERINFO` | - | `https://gitlab.com/oauth/userinfo` |
| `opmet.nginx.NGINX_PORT_HTTP` | Port used for nginx | `80` |
| `opmet.nginx.EXTERNAL_HOSTNAME` | - | `localhost:80` |
| `opmet.nginx.OPMET_BACKEND_HOST` | Address where nginx accesses the backend | `localhost:8080` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
