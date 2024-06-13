# Helm chart for smartmet nowcasting model blend

This chart provides "nowcasting_fcst" as a helm application.

[https://github.com/fmidev/nowcasting_fcst]()

# Chart Configuration

Common configuration options:

| Parameter | Description | Default |
|---|---|---|
| environment | Define environment where this chart is installed. Usually: prod or dev | |
| prodType | Define production type of this chart. Usually: prod or preop | |
| cloud | Define cloud where this chart is installed. Usually: fmi or aws | |
| s3.credentials.name | Name of the secret where s3 credentials are found (should have keys `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY`). If this is not defined, anonymous access is tried. |
| serviceaccount.enabled | Define whether this chart should also create a serviceaccount | false


# Installing the Chart

This chart is used as a subchart for smartmet nwc or vire.

In either of those declare a dependency to Chart.yaml:

```
- name: nowcasting-fcst
  version: 1.0.0
  alias: nowcastingFcst
  repository: "https://fmidev.github.io/helm-charts"
```

And in values.yaml of the parent set:

```
nowcastingFcst:
  s3:
    credentials:
      name: nameofthesecret
  resources:
    limits:
      ...
```

# Using the Chart

The application is defined as a job template which runs  `python3 $COMMAND`, where `$COMMAND` describes the command that is run.

eg. `COMMAND=call_interpolation.py --mode model_fcst_smoother ...`