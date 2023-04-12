# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
# Example envs: https://gitlab.com/opengeoweb/opengeoweb/-/blob/master/apps/geoweb/src/assets/config.example.json
# Secret creation docs: https://kubernetes.github.io/ingress-nginx/examples/auth/basic/

frontend:
  url: geoweb.example.com
  auth: <namespace>/<secret-name> or <secret-name>
  db_secret: secretName # Secret should contain client id for login
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret
  env:
    GW_CAP_BASE_URL: https://geoweb.example.com/cap
    GW_APP_URL: https://geoweb.example.com
    GW_GITLAB_PRESETS_PATH: <path-to-presets>
    GW_DEFAULT_THEME: darkTheme | lightTheme
    GW_FEATURE_APP_TITLE: <Geoweb Title>
    GW_PRESET_BACKEND_URL: https://geoweb.example.com/presets
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-frontend fmi/geoweb-frontend --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-frontend fmi/geoweb-frontend -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb geoweb-frontend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the CAP backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `versions.frontend` | Possibility to override application version | `v4.14.1` |
| `frontend.name` | Name of frontend | `geoweb` |
| `frontend.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/opengeoweb` |
| `frontend.commitHash` | Adds commitHash annotation to the deployment | |
| `frontend.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `frontend.url` | Url which the application can be accessed | |
| `frontend.auth` | Basic auth secret | |
| `frontend.svcPort` | Port used for service | `80` |
| `frontend.containerPort` | Port used for container | `8080` |
| `frontend.replicas` | Amount of replicas deployed | `1` |
| `frontend.db_secret` | Secret containing OAuth2 Provider Client ID | |
| `frontend.iamRoleARN` | IAM Role with permissions to access db_secret secret | |
| `frontend.env.GW_CAP_BASE_URL` | Url which the application uses to connect to CAP backend | |
| `frontend.env.GW_APP_URL` | Url which the application can be accessed | |
| `frontend.env.GW_GITLAB_PRESETS_PATH` | Path in repository to fetch screen presets | |
| `frontend.env.GW_DEFAULT_THEME` | Default theme: lightMode or darkMode | |
| `frontend.env.GW_FEATURE_APP_TITLE` | Application title | |
| `frontend.env.GW_PRESET_BACKEND_URL` | Url which the application uses to connect to Presets backend | |
| `frontend.env.GW_AUTH_LOGOUT_URL` | Url to redirect when logging out | `"http://localhost:5400"` |
| `frontend.env.GW_AUTH_TOKEN_URL` | - | `https://gitlab.com/oauth/token` |
| `frontend.env.GW_AUTH_LOGIN_URL` | Url to redirect when logging in | `https://gitlab.com/oauth/authorize?client_id={client_id}&response_type=code&scope=email+openid+read_repository+read_api&redirect_uri={app_url}/code&state={state}&code_challenge={code_challenge}&code_challenge_method=S256` |
| `frontend.env.GW_INFRA_BASE_URL` | - | `https://api.opengeoweb.com` |
| `frontend.env.GW_GITLAB_PRESETS_BASE_URL` | Base url to fetch screen presets | `https://gitlab.com/api/v4/projects` |
| `frontend.env.GW_GITLAB_PRESETS_API_PATH` | Path in gitlab to fetch screen presets | `/{project_id}/repository/files/{presets_path}{preset_filename}/raw?ref={branch}` |
| `frontend.env.GW_GITLAB_PROJECT_ID` | Project id of gitlab project to fetch screen presets | `"24089222"` |
| `frontend.env.GW_GITLAB_BRANCH` | Branch to fetch screen presets | `master` |
| `frontend.env.GW_INITIAL_PRESETS_FILENAME` | Filename to fetch initial presets | `initialPresets.json` |
| `frontend.env.GW_SCREEN_PRESETS_FILENAME` | Filename to fetch screen presets | `screenPresets.json` |
| `frontend.env.GW_FEATURE_FORCE_AUTHENTICATION` | Force authentication (block Guest access) | `false` |
| `frontend.env.GW_FEATURE_MODULE_SPACE_WEATHER` | Enable Space Weather module | `false` |
| `frontend.env.GW_FEATURE_MODULE_TAF` | Enable TAF module | `false` |
| `frontend.env.GW_FEATURE_MODULE_SIGMET` | Enable SIGMET module | `false` |
| `frontend.env.GW_FEATURE_MODULE_AIRMET` | Enable AIRMET module | `false` |
| `frontend.env.GW_FEATURE_MENU_SATCOMP` | Enable SATCOMP menu option | `false` |
| `frontend.env.GW_FEATURE_MENU_FEEDBACK` | Enable Feedback menu option | `false` |
| `frontend.env.GW_FEATURE_MENU_INFO` | Enable Info menu option | `true` |
| `frontend.env.GW_FEATURE_MENU_VERSION` | Enable Version menu option | `false` |
| `frontend.env.GW_FEATURE_MENU_FE_VERSION` | Enable FE Version menu option | `true` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |