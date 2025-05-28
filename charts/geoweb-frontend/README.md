# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create your own values file for required variables:

* Minimal setup
```yaml
frontend:
  url: geoweb.example.com
```

* Using aws as the secret provider
```yaml
# Example envs: https://gitlab.com/opengeoweb/opengeoweb/-/blob/master/apps/geoweb/src/assets/config.example.json
# Secret creation docs: https://kubernetes.github.io/ingress-nginx/examples/auth/basic/

frontend:
  url: geoweb.example.com
  auth_secret: reference_to_auth_secret
  client_id_secret: reference_to_client_id_secret
  iamRoleARN: arn:aws:iam::123456789012:role/example-iam-role-with-permissions-to-secret
  env:
    GW_CAP_BASE_URL: https://geoweb.example.com/cap
    GW_APP_URL: https://geoweb.example.com
    GW_DEFAULT_THEME: darkTheme | lightTheme
    GW_FEATURE_APP_TITLE: <Geoweb Title>
    GW_PRESET_BACKEND_URL: https://geoweb.example.com/presets

secretProvider: aws
secretProviderParameters:
  region: your-region
```

* Using base64 encoded secrets
```yaml
frontend:
  url: geoweb.example.com
  auth_secret: base64_encoded_basic_auth
  client_id_secret: base64_encoded_client_id_secret
  env:
    GW_CAP_BASE_URL: https://geoweb.example.com/cap
    GW_APP_URL: https://geoweb.example.com
    GW_DEFAULT_THEME: darkTheme | lightTheme
    GW_FEATURE_APP_TITLE: <Geoweb Title>
    GW_PRESET_BACKEND_URL: https://geoweb.example.com/presets

```

* Using custom configuration files stored locally
```yaml
frontend:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationFolderPath: /example/path/
```

* Using custom configuration files stored in AWS S3
```yaml
frontend:
  url: geoweb.example.com
  useCustomConfigurationFiles: true
  customConfigurationLocation: s3
  s3bucketName: example-bucket
  customConfigurationFolderPath: /example/path/
  awsAccessKeyId: <AWS_ACCESS_KEY_ID>
  awsAccessKeySecret: <AWS_SECRET_ACCESS_KEY>
  awsDefaultRegion: <AWS_DEFAULT_REGION>
```

* Generate custom initialPresets.json from YAML values
  * The configuration will be converted to JSON and mounted into the containers filesystem
  * The structure of the JSON file should conform to the InitialAppPresetProps type, see https://opengeoweb.gitlab.io/opengeoweb/typescript-docs/core/interfaces/InitialAppPresetProps.html
  * See also the default initialPresets.json file https://gitlab.com/opengeoweb/opengeoweb/-/blob/master/apps/geoweb/src/assets/initialPresets.json?ref_type=heads
```yaml
frontend:
  url: geoweb.example.com
  env:
    GW_INITIAL_PRESETS_FILENAME: custom/initialPresets.json  # Configure app to use the generated custom configuration JSON
  customConfiguration:
    enabled: true  # Enable initialPresets JSON generation from YAML values
    files:
      "initialPresets.json":  # File will be available at /usr/share/nginx/html/assets/custom/
        # All the settings configured below will be included in the generated initialPresets JSON file
        preset:
          presetType: "mapPreset"
          presetId: "mapPreset-1"
          presetName: "Layer manager preset"
          defaultMapSettings:
            proj:
              bbox:
                left: 58703.6377
                bottom: 6408480.4514
                right: 3967387.5161
                top: 11520588.9031
              srs: "EPSG:3857"
            layers:
              - name: "WorldMap_Light_Grey_Canvas"
                type: "twms"
                enabled: true
                layerType: "baseLayer"
              - service: "https://geoservices.knmi.nl/wms?DATASET=baselayers"
                name: "countryborders"
                format: "image/png"
                enabled: true
                layerType: "overLayer"
          # Additional sections can be specified here including
          # timeSeriesServices:
          # soundingsCollections:
          # services:
          # baseServices:
          # layers:
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install geoweb-frontend fmi/geoweb-frontend --dry-run --debug --namespace geoweb --values=./<yourvaluesfile>.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install geoweb-frontend fmi/geoweb-frontend --namespace geoweb --values=./<yourvaluesfile>.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete --namespace geoweb geoweb-frontend
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the GeoWeb frontend chart and their default values specified in file values.yaml.

| Parameter | Description | Default |
| - | - | - |
| `versions.frontend` | Possibility to override application version | |
| `frontend.name` | Name of frontend | `geoweb` |
| `frontend.registry` | Registry to fetch image | `registry.gitlab.com/opengeoweb/opengeoweb` |
| `frontend.commitHash` | Adds commitHash annotation to the deployment | |
| `frontend.imagePullPolicy` | Adds option to modify imagePullPolicy | |
| `frontend.url` | Url which the application can be accessed | |
| `frontend.svcPort` | Port used for service | `80` |
| `frontend.containerPort` | Port used for container | `8080` |
| `frontend.replicas` | Amount of replicas deployed | `1` |
| `frontend.minPodsAvailable` | Minimum available pods in pod disruption budget. Value `0` omits the pdb. | `0` |   
| `frontend.auth_secret` | Secret containing base64 encoded Basic auth secret | |
| `frontend.auth_secretName` | Name of auth secret | `geoweb-auth` |
| `frontend.auth_secretType` | Type of auth secret | `secretsmanager` |
| `frontend.auth_secretPath` | Path to auth secret | |
| `frontend.auth_secretKey` | Key of auth secret | |
| `frontend.client_id_secret` | Secret containing base64 encoded OAuth2 Provider Client ID | |
| `frontend.client_id_secretName` | Name of id secret | `geoweb-client-id` |
| `frontend.client_id_secretType` | Type to id secret | `secretsmanager` |
| `frontend.client_id_secretPath` | Path to id secret | |
| `frontend.client_id_secretKey` | Key of id secret | |
| `frontend.iamRoleARN` | IAM Role with permissions to access secrets | |
| `frontend.secretServiceAccount` | Service Account created for handling secrets | `geoweb-service-account` |
| `frontend.resources` | Configure resource limits & requests | see defaults from `values.yaml` |
| `frontend.startupProbe` | Configure startupProbe | see defaults from `values.yaml` |
| `frontend.livenessProbe` | Configure livenessProbe | see defaults from `values.yaml` |
| `frontend.readinessProbe` | Configure readinessProbe | see defaults from `values.yaml` |
| `secretProvider` | Option to use secret provider instead of passing base64 encoded Client ID as opmet.db_secret *(aws\|azure\|gcp\|vault)* | |
| `secretProviderParameters` | Option to add custom parameters to the secretProvider, for example with aws you can specify region | |
| `frontend.env.GW_CAP_BASE_URL` | Url which the application uses to connect to CAP backend | |
| `frontend.env.GW_DRAWINGS_BASE_URL` | Url which the application uses to connect to Drawings backend | |
| `frontend.env.GW_TAF_BASE_URL` | Url which the application uses to connect to TAF backend | |
| `frontend.env.GW_SW_BASE_URL` | Url which the application uses to connect to Space Weather backend | |
| `frontend.env.GW_LOCATION_BASE_URL` | Url which the application uses to connect to location backend | |
| `frontend.env.GW_APP_URL` | Url which the application can be accessed | |
| `frontend.env.GW_DEFAULT_THEME` | Default theme: lightMode or darkMode | |
| `frontend.env.GW_FEATURE_APP_TITLE` | Application title | |
| `frontend.env.GW_PRESET_BACKEND_URL` | Url which the application uses to connect to Presets backend | |
| `frontend.env.GW_AUTH_LOGOUT_URL` | Url to redirect when logging out | `"http://localhost:5400"` |
| `frontend.env.GW_AUTH_TOKEN_URL` | Url to retrieve tokens | `https://gitlab.com/oauth/token` |
| `frontend.env.GW_AUTH_LOGIN_URL` | Url to redirect when logging in | `https://gitlab.com/oauth/authorize?client_id={client_id}&response_type=code&scope=email+openid+read_repository+read_api&redirect_uri={app_url}/code&state={state}&code_challenge={code_challenge}&code_challenge_method=S256` |
| `frontend.env.GW_AUTH_ROLE_CLAIM_NAME` | The name of the ID token claim containing the security groups used with the roles | |
| `frontend.env.GW_AUTH_ROLE_CLAIM_VALUE_PRESETS_ADMIN` | The name of the security group required for the preset-admin role | |
| `frontend.env.GW_INITIAL_PRESETS_FILENAME` | Filename to fetch initial presets | `initialPresets.json` |
| `frontend.env.GW_CAP_CONFIGURATION_FILENAME` | Filename to fetch CAP Warnings configured feeds | `capWarningPresets.json` |
| `frontend.env.GW_TIMESERIES_CONFIGURATION_FILENAME` | Filename to fetch TimeSeries preset locations | `timeSeriesPresetLocations.json` |
| `frontend.env.GW_FEATURE_FORCE_AUTHENTICATION` | Force authentication (block Guest access) | `false` |
| `frontend.env.GW_FEATURE_MODULE_SPACE_WEATHER` | Enable Space Weather module | `false` |
| `frontend.env.GW_FEATURE_MENU_FEEDBACK` | Enable Feedback menu option | `false` |
| `frontend.env.GW_FEATURE_MENU_INFO` | Enable Info menu option | `true` |
| `frontend.env.GW_FEATURE_MENU_VERSION` | Enable Version menu option | `false` |
| `frontend.env.GW_FEATURE_MENU_FE_VERSION` | Enable FE Version menu option | `true` |
| `frontend.env.GW_FEATURE_INITIALIZE_SENTRY` | Enable Sentry in this environment | `true` |
| `frontend.env.GW_SIGMET_BASE_URL` | Url which the application uses to connect to SIGMET backend | |
| `frontend.env.GW_AIRMET_BASE_URL` | Url which the application uses to connect to AIRMET backend | |
| `frontend.env.GW_FEATURE_MODULE_SIGMET_CONFIGURATION` | Configuration used by SIGMET module | |
| `frontend.env.GW_FEATURE_MODULE_AIRMET_CONFIGURATION` | Configuration used by AIRMET module | |
| `frontend.env.GW_LANGUAGE` | Set language | |
| `frontend.env.GW_FEATURE_DISPLAY_SEARCH_ON_MAP` | Enable geolocation search | |
| `frontend.env.GW_VERSION_PROGRESS_NOTES_URL` | URL to release notes | |
| `frontend.env.GW_TECHNICAL_RELEASE_NOTES_URL` | URL to technical changelog | |
| `frontend.env.GW_INITIAL_WORKSPACE_PRESET` | Name of the workspace preset that is opened initially | | 
| `frontend.useCustomConfigurationFiles` | Use custom configurations | `false` |
| `frontend.customConfigurationLocation` | Where custom configurations are located *(local\|s3)* | `local` |
| `frontend.customConfiguration.files` | Map of filename to JSON content structured as YAML | `{}` |
| `frontend.customConfiguration.files."initialPresets.json"` | Configuration for map presets, services, layers, etc. | See example in `values.yaml` |
| `frontend.volumeAccessMode` | Permissions of the application for the custom configurations PersistentVolume used | `ReadOnlyMany` |
| `frontend.volumeSize` | Size of the custom configurations PersistentVolume | `100Mi` |
| `frontend.customConfigurationFolderPath` | Path to the folder which contains custom configurations | |
| `frontend.customConfigurationMountPath` | Folder used to mount custom configurations | `/usr/share/nginx/html/assets/custom` |
| `frontend.s3bucketName` | Name of the S3 bucket where custom configurations are stored | |
| `frontend.awsAccessKeyId` | AWS_ACCESS_KEY_ID for authenticating to S3 | |
| `frontend.awsAccessKeySecret` | AWS_SECRET_ACCESS_KEY for authenticating to S3 | |
| `frontend.awsDefaultRegion` | Region where your S3 bucket is located | |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress-controller` |
| `ingress.ingressClassName` | Set ingressClassName parameter to not use default ingressClass | `nginx` |
| `ingress.tls` | TLS configuration section for the ingress | |
| `ingress.rules` | Extra nginx configuration rules, like cache headers | See reference in `values.yaml` |
| `ingress.customAnnotations` | Custom annotations for ingress, for example <pre>customAnnotations:<br>  traefik.annotation: exampleValue</pre> Overrides default nginx annotations and `frontend.auth_secret`, `frontend.auth_secretName` and `ingress.rules` can't be used if set | |

# Chart versions

| Chart version | frontend version |
|---------------|------------------|
| 3.20.0        | 12.6.0           |
| 3.19.1        | 12.4.2           |
| 3.19.0        | 12.3.0           |
| 3.18.1        | 12.3.0           |
| 3.18.0        | 12.1.2           |
| 3.17.4        | 12.1.2           |
| 3.17.3        | 11.0.0           |
| 3.17.2        | 10.0.0           |
| 3.17.1        | 9.37.0           |
| 3.17.0        | 9.34.0           |
| 3.16.2        | 9.34.0           |
| 3.16.1        | 9.31.0           |
| 3.16.0        | 9.30.0           |
| 3.15.1        | 9.30.0           |
| 3.15.0        | 9.29.0           |
| 3.12.2        | 9.26.0           |
| 3.12.1        | 9.19.0           |
| 3.11.1        | 9.19.0           |
| 3.11.0        | 9.18.0           |
| 3.10.2        | 9.18.0           |
| 3.10.1        | 9.17.0           |
| 3.10.0        | 9.14.0           |
| 3.9.0         | 9.14.0           |
| 3.8.1         | 9.14.0           |
| 3.4.0         | 9.9.0            |
| 3.3.0         | 9.6.0            |
| 3.2.0         | 9.5.0            |
