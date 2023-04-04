# Install the chart repository

```bash
helm repo add fmi https://fmidev.github.io/helm-charts/
helm repo update
```

# Create requried dependencies

Create values.yaml file for required variables:
```yaml
secrets:
  secretNames:
    - secret1
    - secret2
  iamRoleARN: arn:aws:iam::012345678901:role/example-iam-service-account-role
```

# Testing the Chart
Execute the following for testing the chart:

```bash
helm upgrade secrets fmi/geoweb-secrets-provider-aws --dry-run --install --debug -n geoweb --values=./values.yaml
```

# Installing the Chart

Execute the following for installing the chart:

```bash
helm install secrets fmi/secrets -n geoweb --values=./values.yaml
```

# Deleting the Chart
Execute the following for deleting the chart:

```bash
## Delete the Helm Chart
helm delete -n geoweb secrets
## Delete the Namespace
kubectl delete namespace geoweb
```

# Chart Configuration
The following table lists the configurable parameters of the CAP backend chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `secrets.provider` | Which cloud provider to use | `aws` |
| `secrets.namespace` | Which namespace to use | `kube-system` |
| `secrets.syncRoleName` | Name of syncing role | `secretprovidersyncing` |
| `secrets.spcRoleName` | Name of secret provider class role | `secretproviderclasses` |
| `secrets.spcName` | Name of secret provider class | `aws-secrets` |
| `secrets.csiName` | Name of secret store driver | `csi-secrets-store` |
| `secrets.serviceAccountName` | Name of secret service account | `geoweb-eks-secret-service-account` |
| `secrets.csiServiceAccountName` | Name of secret store driver service account | `secrets-store-csi-driver` |
| `secrets.secretNames` | List of secrets fetched from AWS Secrets Manager | |
| `secrets.iamRoleARN` | IAM Role ARN which fetches secrets | |
| `providerAwsInstaller.name` | Name of AWS Provider Installer | `provider-aws-installer` |
| `providerAwsInstaller.registry` | Registry to fetch image | `public.ecr.aws/aws-secrets-manager/secrets-store-csi-driver-provider-aws` |
| `providerAwsInstaller.version` | Possibility to override application version | `1.0.r2-35-g41dc61e-2022.12.16.20.38` |
| `nodeDriverRegistrar.name` | Name of Node Driver Registrar | `node-driver-registrar` |
| `nodeDriverRegistrar.registry` | Registry to fetch image | `registry.k8s.io/sig-storage/csi-node-driver-registrar` |
| `nodeDriverRegistrar.version` | Possibility to override application version | `v2.6.2` |
| `secretsStore.name` | Name of Secrets Store | `secrets-store` |
| `secretsStore.registry` | Registry to fetch image | `registry.k8s.io/csi-secrets-store/driver` |
| `secretsStore.version` | Possibility to override application version | `v1.3.0` |
| `livenessProbe.name` | Name of Liveness Probe | `liveness-probe` |
| `livenessProbe.registry` | Registry to fetch image | `registry.k8s.io/sig-storage/livenessprobe` |
| `livenessProbe.version` | Possibility to override application version | `v2.8.0` |