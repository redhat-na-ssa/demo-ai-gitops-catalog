# Notes

## Commands

Create sts-creds

```sh
ARN=$(aws sts get-caller-identity --query "Arn" --output text)

echo ${ARN}
sed "s@\${ARN}@${ARN}@g" assume-role.json > scratch/assume-role.json
```

```sh
ROLE_ARN=$(aws iam create-role \
  --role-name hcp-cli-role \
  --assume-role-policy-document file://scratch/assume-role.json \
  --query "Role.Arn")

# ROLE_ARN=${ROLE_ARN#\"arn:aws:iam::}
# ROLE_ARN=${ROLE_ARN%:role/hcp-cli-role\"}

echo ${ROLE_ARN}
```

```sh
aws iam put-role-policy \
  --role-name hcp-cli-role \
  --policy-name hcp-cli-policy \
  --policy-document file://policy.json
```

```sh
aws sts get-session-token --output json > scratch/sts-creds.json
```

Create hcp aws cluster

```sh
oc new-project clusters

OCP_DOMAIN=$(ocp_get_domain)
BASE_DOMAIN=${OCP_DOMAIN/*.sandbox/sandbox}

# Set environment variables
export REGION="us-east-2"
export CLUSTER_NAME="hosted-0"
export STS_CREDS="scratch/sts-creds.json"
export NAMESPACE="clusters"
export ROLE_ARN="${ROLE_ARN}"
export PULL_SECRET=scratch/pull-secret
export BASE_DOMAIN=${BASE_DOMAIN}

# fix missing cm
oc patch cloudcredential cluster \
  --type=merge \
  --patch '{"spec":{"credentialsMode":"Manual"}}'

hcp create cluster aws \
  --name $CLUSTER_NAME \
  --namespace $NAMESPACE \
  --node-pool-replicas=3 \
  --sts-creds $STS_CREDS \
  --role-arn $ROLE_ARN \
  --pull-secret $PULL_SECRET \
  --region $REGION \
  --base-domain $BASE_DOMAIN

hcp destroy cluster aws \
  --name $CLUSTER_NAME \
  --namespace $NAMESPACE \
  --sts-creds $STS_CREDS \
  --role-arn $ROLE_ARN \
  --region $REGION \
  --base-domain $BASE_DOMAIN
```
