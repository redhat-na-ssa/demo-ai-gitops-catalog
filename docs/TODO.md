# TODO Items

- [ ] add: create example jupyter containers with ubi base
- [ ] scripted: caching mirror registry
- [ ] add: openldap w/ idp and ldapsync example
  - https://www.linkedin.com/pulse/deploying-openldap-openshift-users-bootstrapped-ritesh-raj
- [ ] add: image streams for custom jupyter notebooks
  - https://github.com/opendatahub-io-contrib/workbench-images
  - Without image streams this is cumbersome
  - Build from known bases for security
- [ ] Review: AWS user security. Limit access to the OCP provisioner account (reassign `Administrator' role to something limited)

## Review Links

- https://github.com/argoproj/argocd-example-apps/blob/master/plugins/kustomized-helm/README.md
- https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#_helmchartinflationgenerator
- https://github.com/viaduct-ai/kustomize-sops
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/bootstrap/argocd.yaml#L86
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/bootstrap/kustomization.yaml#L8
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/applications/alertmanager.yaml#L21
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/encrypt-chart-secrets.sh
- https://krew.sigs.k8s.io/docs/user-guide/setup/install/#bash