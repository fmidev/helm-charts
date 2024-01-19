# Job serviceaccount

This chart creates a serviceaccount that can process templates and launch jobs.

# Chart Configuration

| Parameter | Description | Default |
|---|---|---|
| serviceAccount.name | Name for this serviceaccount | testaccount |


# Installing the Chart

```
helm install app-robot -f values.yaml --set serviceAccount.name=app-robot .
```
