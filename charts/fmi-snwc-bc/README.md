# Helm chart for smartmet nowcasting biascorrection

This chart provides "snwc_bc" as a helm application.

[https://github.com/fmidev/snwc_bc]()

# Chart Configuration

Common configuration options:

| Parameter | Description | Default |
|---|---|---|
| environment | Define environment where this chart is installed. Usually: prod or dev | |
| prodType | Define production type of this chart. Usually: prod or preop | |
| cloud | Define cloud where this chart is installed. Usually: fmi or aws | |
| s3.credentials.name | Name of the secret where s3 credentials are found (should have keys `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY`). If this is not defined, anonymous access is tried. |
| tiuha.credentials.name | Name of the secret where tiuha credentials are found (should have key `SNWC1_KEY`. If this is not defined, netatmo observation access is not possible. |
| serviceaccount.enabled | Define whether this chart should also create a serviceaccount | false


# Installing the Chart

This chart is used as a subchart for smartmet nwc or vire.

In either of those declare a dependency to Chart.yaml:

```
- name: snwc-bc
  version: 1.0.0
  alias: biascorrection
  repository: "https://fmidev.github.io/helm-charts"
```

And in values.yaml of the parent set:

```
biascorrection:
  s3:
    credentials:
      name: ...
  tiuha:
    credentials:
      name: ...
  resources:
    limits:
      ...
```

# Using the Chart

The application is defined as a job template which needs three parameters:

* INPUT_DIR: directory where all source data is located, can be local directory or s3 bucket
* OUTPUT_FILE: filename where results are written, can be a local file or an object
* PARAM: name of the parameter

The job-template runs then this command:

```
python3 biasc.py \
    --topography_data ${INPUT_DIR}/Z-M2S2.grib2 \
    --landseacover ${INPUT_DIR}/LC-0TO1.grib2 \
    --t2_data ${INPUT_DIR}/T-K.grib2 \
    --wg_data ${INPUT_DIR}/FFG-MS.grib2 \
    --nl_data ${INPUT_DIR}/NL-0TO1.grib2 \
    --ppa_data ${INPUT_DIR}/P-PA.grib2 \
    --wd_data ${INPUT_DIR}/DD-D.grib2 \
    --q2_data ${INPUT_DIR}/Q-KGKG.grib2 \
    --ws_data ${INPUT_DIR}/FF-MS.grib2 \
    --rh_data ${INPUT_DIR}/RH-0TO1.grib2 \
    --output ${OUTPUT_FILE} \
    --parameter ${PARAM}
```

