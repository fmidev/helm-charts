# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
certificateARN: arn:aws:acm:0123456789012:certificate/certificate-id
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm install nginx-ingress-controller fmi/nginx-ingress-controller --dry-run --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install nginx-ingress-controller fmi/nginx-ingress-controller -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb nginx-ingress-controller
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the CAP backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `ingress.registry` | Registry to fetch image | `registry.k8s.io/ingress-nginx/controller` |
| `ingress.version` | Possibility to override application version | `v1.5.1@sha256:4ba73c697770664c1e00e9f968de14e08f606ff961c76e5d7033a4a9c593c629` |
| `ingress.name` | Name of ingress controller | `nginx-ingress-controller` |
| `loadBalancerType` | Load balancer type used in AWS | `nlb` |
| `certificateARN` | Certificate for your domain name | |