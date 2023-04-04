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
helm install secrets fmi/geoweb-secrets-provider-aws -n geoweb --values=./values.yaml
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
The following table lists the configurable parameters of the geoweb-secrets-provider-aws chart and their default values.

| Parameter | Description | Default |
| - | - | - |
| `secrets.provider` | Which cloud provider to use | `aws` |
| `secrets.namespace` | Which namespace to use | `kube-system` |
| `secrets.spcName` | Name of secret provider class | `aws-secrets` |
| `secrets.csiName` | Name of secret store driver | `csi-secrets-store` |
| `secrets.serviceAccountName` | Name of secret service account | `geoweb-eks-secret-service-account` |
| `secrets.secretNames` | List of secrets fetched from AWS Secrets Manager | |
| `secrets.iamRoleARN` | IAM Role ARN which fetches secrets | |
| `providerAwsInstaller.name` | Name of AWS Provider Installer | `provider-aws-installer` |
| `providerAwsInstaller.registry` | Registry to fetch image | `public.ecr.aws/aws-secrets-manager/secrets-store-csi-driver-provider-aws` |
| `providerAwsInstaller.version` | Possibility to override application version | `1.0.r2-35-g41dc61e-2022.12.16.20.38` |