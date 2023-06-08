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
| `image.repository` | Portainer Docker Hub repository | `fmidev/smartmetserver` |
| `image.tag` | Tag for the Portainer image | `latest` |
| `image.pullPolicy` | Portainer image pulling policy | `IfNotPresent` |
| `smartmetserver.name` | Name of server | `smartmetserver` |
| `smartmetserver.containerPort` | Port used for container | `8080` |
| `smartmetserver.svcPort` | Port used for service | `8080` |
| `smartmetserver.replicas` | Amount of replicas deployed | `2` |
| `ingress.name` | Name of the ingress controller in use | `nginx-ingress` |
| `pvc.name` | Name of the persistent volume claim in use | `pvc` |
| `pvc.storageClassName` | Name of storageClassName of volume pvc is tryoing to bound to | `local` |
| `pvc.accessModes` | Type of access modes persistent volume claim supports  | `ReadWriteOnce` |
| `pvc.storage` | The amount of storage for persistent volume claim  | `1Gi` |
