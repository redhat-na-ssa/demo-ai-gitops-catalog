# Consistent list of issues with RHOAI

## General Issues

- [ ] Current RHOAI documentation [does not explain GPU operation](https://ai-on-openshift.io/odh-rhods/nvidia-gpus/) with RHOAI well
- [ ] `odh-dashboard-conf` needs `groupsConfig` to [setup RBAC](../../components/configs/kustomized/rhoai-config/dashboard-config-cr.yaml) - over-engineered dashboard, poor security
- [ ] Poorly documented, inconsistent labels to display resources in dashboard
  - Why are [data sci projects](components/configs/kustomized/rhoai-projects) different than regular projects?
  - label `app.kubernetes.io/created-by: byon`
- [ ] You can't customize the list of potential notebook images per namespace for multi-homed use cases.
  - Ex: everyone on the cluster sees the same notebook images - list can get very big.
- [ ] CUDA based images do not use Nvidia's CUDA as the official base (Poor Maintenance)

## Data Science Pipelines

- [ ] Do they really work? Maybe, Sometimes, No
- [ ] Pipelines are stored in the mariadb instance instead of cluster resources like a CR
  - Table `run_details` contains field `WorkflowSpecManifest` contains `PipelineRun`
- [ ] `mariadb-pipelines-definition` Deployment sets env var `MYSQL_ALLOW_EMPTY_PASSWORD=true` (Security: Data Exposure)
  - `mysqldump -u root -A -n < svc >`

## Potential enhancements

- [ ] Move config for idle notebooks to CR vs [configmap](../../components/configs/kustomized/rhoai-config/nb-culler-config.yaml)
