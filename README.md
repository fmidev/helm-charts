## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add fmi https://fmidev.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
<alias>` to see the charts.

To install the <chart-name> chart:

    helm install my-<chart-name> <alias>/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>

## Instance specific values not included in the Charts


### Geoweb frontend

```
# Example envs: https://gitlab.com/opengeoweb/opengeoweb/-/blob/master/apps/geoweb/src/assets/config.example.json
# Secret creation docs: https://kubernetes.github.io/ingress-nginx/examples/auth/basic/

frontend:
  url: geoweb.example.com
  auth: <namespace>/<secret-name> or <secret-name>
  env:
    GW_AUTH_CLIENT_ID: <Application ID>
    GW_CAP_BASE_URL: https://geoweb.example.com/cap
    GW_APP_URL: https://geoweb.example.com
    GW_GITLAB_PRESETS_PATH: <path-to-presets>
    GW_DEFAULT_THEME: darkTheme | lightTheme
    GW_FEATURE_APP_TITLE: <Geoweb Title>
    GW_PRESET_BACKEND_URL: https://geoweb.example.com/presets
```

### Cap backend

```
cap:
  url: geoweb.example.com
```

### Presets backend

```
presets:
  url: geoweb.example.com
  PRESETS_BACKEND_DB: postgresql://[user[:password]@][netloc][:port][/dbname]
```

### Opmet backend

```
# Both should use same database

opmet:
  url: geoweb.example.com
  env:
    SQLALCHEMY_DATABASE_URL: "postgresql://[user[:password]@][netloc][:port][/dbname]"
    TEST_SQLALCHEMY_DATABASE_URL: "postgresql://[user[:password]@][netloc][:port][/dbname]"
```