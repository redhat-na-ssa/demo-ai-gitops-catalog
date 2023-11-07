# Consistent list of issues with RHODS

- [ ] Notebook GPU toleration not configurable
- [ ] Current RHODS documentation [does not explain GPU operation](https://ai-on-openshift.io/odh-rhods/nvidia-gpus/) with RHODS well
- [ ] `odh-dashboard-conf` needs `gpuSetting` to [consistently show GPUs when autoscaling](../../components/configs/kustomized/rhods/odh-dashboard-config-cr.yaml) - over-engineered dashboard
- [ ] Why are [data sci projects](components/configs/kustomized/rhods-projects) different than regular projects?
- [ ] You can't customize the list of potential notebook images per namespace for multi-homed use cases.
  - Ex: everyone on the cluster sees the same notebook images.

## Potential enhancements

- [ ] Move config for idle notebooks to CR vs [configmap](../../components/configs/kustomized/rhods/nb-culler-config.yaml)
