# himan-chart

Helm chart for Himan

Himan source: https://github.com/fmidev/himan.git

# Contents

Chart contains configuration for Himan openshift job template.

If values.configuration is enabled, chart will create a BuildConfiguration that will clone
a git repo that (supposedly) contains the configuration files for Himan.

If values.configuration is disabled, chart will just import Himan image from quay.io.

# Preconditions

Necessary passwords and accounts need to be created before creating the chart.

radon-credentials are given with secret 'radon-credentials' (configurable), secret should contain at least the following field:

* RADON_WETODB_PASSWORD

s3-credentials are given with secret 's3-credentials' (configurable), secret should contain following fields

* S3_ACCESS_KEY_ID
* S3_SECRET_ACCESS_KEY

If no credentials are needed for s3 access, leave field s3.credentials.name empty.

# Usage

helm create himan . -f values.yaml 

Or as a subchart:

```yaml
dependencies:
  - name: himan
    version: 1.0.0
    repository: "https://fmidev.github.io/helm-charts"
```

Nearly all of the options of Himan are exposed to the job template. See the template for more details.
