# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install smartmetserver fmi/smartmetserver --dry-run --debug -n smartmetserver --create-namespace --values=./values.yaml
```

# Installing the Chart
Execute the following for installing the chart:

```bash
helm install smartmetserver fmi/smartmetserver -n smartmetserver --create-namespace --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n smartmetserver smartmetserver
## Delete the Namespace
kubectl delete namespace smartmetserver
```

# Chart Configuration
The following table lists the configurable parameters of the Smartmetserver chart and their default values.

*The parameters will be keep updating.*

| Parameter | Description | Default |
| - | - | - |
| `image.repository` | Docker Hub repository | `fmidev/smartmetserver` |
| `image.tag` | Tag for the smartmetserver image | `latest` |
| `image.pullPolicy` | Adds option to modify imagePullPolicy | `IfNotPresent` |
| `smartmetserver.name` | Name of server | `smartmetserver` |
| `smartmetserver.containerPort` | Port used for container | `8080` |
| `smartmetserver.svcPort` | Port used for service | `8080` |
| `smartmetserver.replicas` | Amount of replicas deployed | `2` |
| `smartmetserver.livenessProbe.periodSeconds` | Liveness probe's delay between probing attemps | `30` |
| `smartmetserver.readinessProbe.failureThreshold` | How many times the probe attemps before restarting the container | `5` |
| `smartmetserver.readinessProbe.periodSeconds` | Readiness probe's delay between probing attemps | `60` |
| `smartmetserver.startupProbe.failureThreshold` | How many times the probe attemps before restarting the container | `5` |
| `smartmetserver.startupProbe.periodSeconds` | Startup probe's delay between probing attemps | `60` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress` |
| `ingress.ingressClassName` | Configure ingressClassName if needed | `""` |
| `pv.enable` | If persisten volume is created | `true` |
| `pv.name` | Name of the persistent volume that is created | `pv` |
| `pv.path` | Path for the hostPath location which persisten volume uses | `/tmp/smartmet-data` |
| `pvc.name` | Name of the persistent volume claim in use | `pvc` |
| `pvc.storageClassName` | Name of storageClassName of volume pvc is tryoing to bound to | `local` |
| `pvc.accessModes` | Type of access modes persistent volume claim supports  | `ReadWriteOnce` |
| `pvc.storage` | The amount of storage for persistent volume claim  | `1Gi` |
| `hpa.name` | Name for horizontal pod autoscaler  | `hpa` |
| `hpa.minReplicas` | Minimum amount of replicas for horizontal pod autoscaler  | `1` |
| `hpa.maxReplicas` | Maximum amount of replicas for horizontal pod autoscaler  | `6` |
| `hpa.targetCPUUtilizationPercentage` | Target cpu percentage for horizontal pod autoscaler  | `60` |
| `smartmetConfCm.name` | Name of the configmap that is created  | `smartmet-cnf` |
| `smartmetConfCm.smartmetConf` | Data for the configmap which matches `smartmet.conf` default config  | `smartmet.conf` default content |


## smartmet.conf
```
// Bind to port
port            = 8080;

// Print access log
defaultlogging  = false;
logrequests     = true;
accesslogdir    = "/var/log/smartmet";

// Print configuration information when starting
verbose         = true;

// Print debug infromation
debug           = true;

lazylinking     = true;

// Compress HTTP responses if possible
compress = true;

// Do not compress small responses
compresslimit = 1000;

slowpool:
{
    maxthreads = 24;
    maxrequeuesize = 100;
};
fastpool:
{
    maxthreads = 24;
    maxrequeuesize = 100;
};

engines:
{
    sputnik:
    {
            configfile = "engines/sputnik.conf";
    }
    contour:
    {
            configfile = "engines/contour.conf";
    };
    geonames:
    {
            configfile = "engines/geonames.conf";
    };
    gis:
    {
            configfile = "engines/gis.conf";
    };
    querydata:
    {
            configfile = "engines/querydata.conf";
    };
    grid:
    {
            configfile = "engines/grid.conf";
    };
};

plugins:
{
    admin:
    {
            configfile = "plugins/admin.conf";
    };
    autocomplete:
    {
            configfile = "plugins/autocomplete.conf";
    };
    download:
    {
            configfile = "plugins/download.conf";
    };
    edr:
    {
            configfile = "plugins/edr.conf";
    };
    timeseries:
    {
            configfile = "plugins/timeseries.conf";
    };
    wms:
    {
            configfile = "plugins/wms.conf";
    };
};
```
