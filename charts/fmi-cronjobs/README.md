# FMI cronjobs (fmi-cronjobs)

Helm chart for deploying multiple Kubernetes CronJobs using the `fmi-cronjob` library chart.

## Usage example

```yaml
fmi-cronjobs:
  defaults:
    pullSecret: my-pull-secret
    pullPolicy: IfNotPresent
    timeZone: Europe/Helsinki
  cronjobs:
    - name: my-job
      enabled: true
      schedule: "1 2,3,4 * * *"
      image:
        repository: example.com/container-repository
        tag: 1.0.0
      command: ["/app/run.sh"]
      mounts: [ ... ]
      tmp:
        enabled: false
      resourcePreset: minimal
```
