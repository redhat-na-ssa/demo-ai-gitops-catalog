# Airflow deployment

## Create an airflow project on OpenShift
```
# create new project
oc new-project airflow
```

## Create a secret for airflow

```
export GIT_SERVER=github.com
export GITHUB_USER=<UPDATED_YOUR_GITHUB_USERNAME>
export GITHUB_TOKEN=<UPDATE_YOUR_GITHUB_TOKEN>

cat <<EOF | oc -n airflow apply -f-
apiVersion: v1
data:
  password: "$(echo -n ${GITHUB_TOKEN} | base64)"
  username: "$(echo -n ${GITHUB_USER} | base64)"
kind: Secret
metadata:
  name: git-auth
type: kubernetes.io/basic-auth
EOF
```

## Install Helm

```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

## Add repo

```
helm repo add eformat https://eformat.github.io/helm-charts
```

## Deploy airflow on OpenShift

```
helm upgrade --install airflow \
--set gitSync.repo="https://github.com/redhat-na-ssa/datasci-fingerprint.git" \
--set gitSync.branch="main" \
--set gitSync.wait="10" \
--namespace airflow \
eformat/airflow
```
