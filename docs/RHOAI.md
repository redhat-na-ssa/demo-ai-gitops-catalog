# Consistent list of issues with RHOAI

## General Issues

- [ ] Current RHOAI documentation [does not explain GPU operation](https://ai-on-openshift.io/odh-rhods/nvidia-gpus/) with RHOAI well
- [ ] `odh-dashboard-conf` needs `groupsConfig` to [setup RBAC](../../components/app-configs/rhoai-config/dashboard-config-cr.yaml) - over-engineered dashboard, poor security
- [ ] Poorly documented, inconsistent labels to display resources in dashboard
  - Why are [data sci projects](components/app-configs/rhoai-projects) different than regular projects?
  - label `app.kubernetes.io/created-by: byon`
- [ ] You can't customize the list of potential notebook images per namespace for multi-homed use cases.
  - Ex: everyone on the cluster sees the same notebook images - list can get very big.
- [ ] CUDA based images do not use Nvidia's CUDA as the official base (Poor Maintenance)

### RHOAI 2.10.0

Out of the Box Issues

FeatureTrackers

Error: redhat-ods-applications-mesh-control-plane-creation

```sh
PreConditionsFailed applying [mesh-control-plane-creation]: 1 error occurred:
* failed to find the pre-requisite Service Mesh Operator subscription, please ensure Service Mesh Operator is installed. failed to find the pre-requisite operator subscription "servicemeshoperator", please ensure operator is installed. missing operator "servicemeshoperator"
```

Error: redhat-ods-applications-mesh-metrics-collection

```sh
Failed applying [mesh-metrics-collection]: 2 errors occurred:
* failed to find Service Mesh Control Plane: no matches for kind "ServiceMeshControlPlane" in version "maistra.io/v2"
* service mesh control plane is not ready
```

DSCInitialization details

Error: default-dsci

```sh
2 errors occurred:
* failed to get object istio-system/data-science-smcp: no matches for kind "ServiceMeshControlPlane" in version "maistra.io/v2"
* 2 errors occurred:
* failed to find Service Mesh Control Plane: no matches for kind "ServiceMeshControlPlane" in version "maistra.io/v2"
* service mesh control plane is not ready
```

## Data Science Pipelines

- [ ] Pipelines are stored in the mariadb instance instead of cluster resources like a CR
  - Table `run_details` contains field `WorkflowSpecManifest` contains `PipelineRun`
- [ ] `mariadb-pipelines-definition` Deployment sets env var `MYSQL_ALLOW_EMPTY_PASSWORD=true` (Security: Data Exposure)
  - `mysqldump -u root -A -n < svc >`

## Potential enhancements

- [ ] Move config for idle notebooks to CR vs [configmap](../../components/app-configs/rhoai-config/nb-culler-config.yaml)
