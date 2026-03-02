# FMI cronjob (fmi-cronjob)

Library Helm chart for rendering a single Kubernetes CronJob.

## Usage

This chart must be used as a dependency from another chart, for example:

```yaml
dependencies:
  - name: fmi-cronjob
    version: X.Y.Z
    repository: "https://fmidev.github.io/helm-charts"
```
