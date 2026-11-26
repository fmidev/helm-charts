# AWS EKS deployment

This guide deploys the GeoWeb Plugin Registry on Amazon EKS using native AWS
S3, IAM roles for service accounts (IRSA), AWS Secrets Manager through the
Secrets Store CSI Driver, and Kubernetes Ingress.

For native AWS S3, set `storage.backend` to `s3` and provide the existing bucket
name and AWS region as Helm values. The chart does not create the bucket. Leave
`storage.s3.endpoint` empty and set `storage.s3.pathStyle` to `false`.

The pod can access AWS through IRSA, or through credentials in
`storage.s3.existingSecret`. With IRSA, create the IAM role outside the chart
and pass its ARN in `serviceAccount.annotations`.

The GitLab OAuth credentials must be available in the Kubernetes Secret named by
`auth.secretName`. Create that Secret separately, for example manually or with a
SealedSecret, or enable `auth.secretProviderClass` to synchronize it from AWS
Secrets Manager. CSI synchronization requires the Secrets Store CSI Driver and
its AWS provider to be installed in the cluster; the chart does not install
them or create the source Secrets Manager secret.

When enabling Ingress, set both `publicUrl` and `ingress.host` to the external
registry address. Set `ingress.className` explicitly, or leave it empty only
when the cluster has a default IngressClass.

## Manual AWS prerequisites with AWS CLI

The following example creates the resources for the IRSA and Secrets Manager CSI
setup. Change the values for each environment. These commands are one-time
provisioning steps and are not run by Helm.

Replace every value enclosed in angle brackets.

```bash
export AWS_PROFILE="<aws-cli-profile>"
export AWS_REGION="<aws-region>"
export CLUSTER_NAME="<eks-cluster-name>"
export KUBERNETES_NAMESPACE="plugin-registry"
export KUBERNETES_SERVICE_ACCOUNT="plugin-registry"
export BUCKET_NAME="<globally-unique-s3-bucket-name>"
export BUCKET_PREFIX=verdaccio
export SECRET_NAME="plugin-registry/oidc"
export ROLE_NAME="plugin-registry"
export ROLE_POLICY_NAME="plugin-registry-policy"

export AWS_ACCOUNT_ID="$(aws sts get-caller-identity \
  --query Account --output text)"
export OIDC_ISSUER="$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.identity.oidc.issuer' \
  --output text)"
export OIDC_PROVIDER="${OIDC_ISSUER#https://}"
```

Verify that the cluster's IAM OIDC provider already exists. This is normally a
cluster-level prerequisite for IRSA and should not be recreated for this chart:

```bash
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn \
  "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"
```

## Create the S3 bucket

Create the private S3 bucket. The `create-bucket` form below is for regions
other than `us-east-1`.

```bash
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$AWS_REGION" \
  --create-bucket-configuration "LocationConstraint=$AWS_REGION"

aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
  'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true'

aws s3api put-bucket-ownership-controls \
  --bucket "$BUCKET_NAME" \
  --ownership-controls 'Rules=[{ObjectOwnership=BucketOwnerEnforced}]'

aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration \
  'Rules=[{ApplyServerSideEncryptionByDefault={SSEAlgorithm=AES256},BucketKeyEnabled=true}]'
```

Add a bucket policy that denies requests made without TLS:

```bash
cat > plugin-registry-bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::$BUCKET_NAME",
        "arn:aws:s3:::$BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket "$BUCKET_NAME" \
  --policy file://plugin-registry-bucket-policy.json
```

## Create the GitLab OAuth secret

Create a local `oidc-secret.json`:

```json
{
  "VERDACCIO_OPENID_CLIENT_ID": "<gitlab-application-id>",
  "VERDACCIO_OPENID_CLIENT_SECRET": "<gitlab-application-secret>"
}
```

Create the Secrets Manager secret and retain its full ARN for the IAM policy.
AWS adds a generated suffix to the ARN, so do not construct it from the secret
name:

```bash
chmod 0600 oidc-secret.json

aws secretsmanager create-secret \
  --name "$SECRET_NAME" \
  --region "$AWS_REGION" \
  --secret-string file://oidc-secret.json

export SECRET_ARN="$(aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" \
  --query ARN \
  --output text)"

rm -f oidc-secret.json
```

## Create the IRSA role

Create the IRSA trust policy. It allows only the chosen service account in the
chosen namespace to assume the role:

```bash
cat > plugin-registry-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPluginRegistryServiceAccount",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$AWS_ACCOUNT_ID:oidc-provider/$OIDC_PROVIDER"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$OIDC_PROVIDER:aud": "sts.amazonaws.com",
          "$OIDC_PROVIDER:sub": "system:serviceaccount:$KUBERNETES_NAMESPACE:$KUBERNETES_SERVICE_ACCOUNT"
        }
      }
    }
  ]
}
EOF

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file://plugin-registry-trust-policy.json
```

Give that role access only to the registry prefix and the one OIDC secret:

```bash
cat > plugin-registry-role-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListRegistryPrefix",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::$BUCKET_NAME",
      "Condition": {
        "StringLike": {
          "s3:prefix": [
            "$BUCKET_PREFIX",
            "$BUCKET_PREFIX/*"
          ]
        }
      }
    },
    {
      "Sid": "ManageRegistryObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": "arn:aws:s3:::$BUCKET_NAME/$BUCKET_PREFIX/*"
    },
    {
      "Sid": "ReadPluginRegistryOidcSecret",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "$SECRET_ARN"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$ROLE_POLICY_NAME" \
  --policy-document file://plugin-registry-role-policy.json

export ROLE_ARN="$(aws iam get-role \
  --role-name "$ROLE_NAME" \
  --query 'Role.Arn' \
  --output text)"

rm -f plugin-registry-bucket-policy.json \
  plugin-registry-trust-policy.json \
  plugin-registry-role-policy.json
```

The example uses the default Secrets Manager encryption key. If the secret uses
a customer-managed KMS key, also grant the role `kms:Decrypt` for that key.

## Verify the AWS configuration

Verify the resulting configuration without printing the secret value:

```bash
aws s3api get-public-access-block --bucket "$BUCKET_NAME"
aws s3api get-bucket-encryption --bucket "$BUCKET_NAME"
aws s3api get-bucket-policy --bucket "$BUCKET_NAME"
aws iam get-role \
  --role-name "$ROLE_NAME" \
  --query 'Role.AssumeRolePolicyDocument'
aws iam get-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$ROLE_POLICY_NAME"
aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION"
```

## Configure GitLab and Helm

Use `ROLE_ARN`, the service-account name, bucket settings, and secret name in
the environment's Helm values. The GitLab application must allow the registry's
three callback URLs:

- `https://<registry-host>/-/oauth/callback/authn`
- `https://<registry-host>/-/oauth/callback`
- `https://<registry-host>/-/oauth/callback/cli`

The GitLab application must allow the scopes configured in `auth.scope`. GitLab
group lookup requires `read_api` in addition to the OpenID scopes.
After rotating the GitLab credentials in Secrets Manager, restart the Deployment
so its environment variables receive the synchronized Kubernetes Secret values.

Configure the chart using
[`values-aws-eks.yaml`](../examples/values-aws-eks.yaml) as a starting point:

```bash
helm upgrade --install plugin-registry charts/geoweb-plugin-registry \
  --namespace plugin-registry \
  --create-namespace \
  --values charts/geoweb-plugin-registry/examples/values-aws-eks.yaml
```

The IAM role needs permission to list the configured prefix and read/write
objects in the bucket. When `auth.secretProviderClass.enabled` is true, it also
needs permission to read the configured Secrets Manager object. Store that
object as JSON using the keys `VERDACCIO_OPENID_CLIENT_ID` and
`VERDACCIO_OPENID_CLIENT_SECRET`. Keep `persistence.enabled` enabled because the
OpenID plugin stores its state at `/verdaccio/storage/openid-store`. In S3 mode,
the chart disables EC2 instance-metadata credentials so a failed IRSA setup
cannot silently fall back to the EKS node role.

## Use an externally managed Kubernetes Secret

If the Secrets Store CSI integration is not used, create the Kubernetes Secret
directly instead, or provide the equivalent Secret through a controller such as
Sealed Secrets:

```bash
kubectl create secret generic plugin-registry-oidc \
  --from-literal=VERDACCIO_OPENID_CLIENT_ID="<gitlab-client-id>" \
  --from-literal=VERDACCIO_OPENID_CLIENT_SECRET="<gitlab-client-secret>" \
  --namespace=plugin-registry
```

Set `auth.secretName` to the resulting Secret name and leave
`auth.secretProviderClass.enabled` set to `false`.
