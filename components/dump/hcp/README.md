# Notes

## Commands

Create sts-creds

```sh
aws sts get-caller-identity --query "Arn" --output text

# arn:aws:iam::1234567890:user/<aws_username>
```

assume-role.json

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "<arn>" 
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```

```sh
aws iam create-role \
  --role-name hcp-cli-role \
  --assume-role-policy-document file://assume-role.json \
  --query "Role.Arn"

# arn:aws:iam::820196288204:role/hcp-cli-role
```

```sh
aws iam put-role-policy \
  --role-name hcp-cli-role \
  --policy-name hcp-cli-policy \
  --policy-document file://policy.json
```

```sh
aws sts get-session-token --output json > sts-creds.json
```

Create hcp aws cluster

```sh
# Set environment variables
export REGION="us-east-1"
export CLUSTER_NAME="example"
export STS_CREDS="example-sts-creds-json"  # JSON file from step 2
export NAMESPACE="example-namespace"
export ROLE_ARN="example-role-arn" # Role ARN from step 3
export PULL_SECRET="example-pull-secret-file" # Pull secret file path from step 4
export BASE_DOMAIN="www.example.com" # Base domain for this cluster

hcp create cluster aws \
  --name $CLUSTER_NAME \
  --namespace $NAMESPACE \
  --node-pool-replicas=3 \
  --sts-creds $STS_CREDS \
  --role-arn $ROLE_ARN \
  --pull-secret $PULL_SECRET \
  --region $REGION \
  --base-domain $BASE_DOMAIN
```
