# TODO Items

- [x] setup: registry w/ `emptyDir` for base ArgoCD config
- [ ] add: image streams for custom jupyter notebooks
  - https://github.com/opendatahub-io-contrib/workbench-images
  - Without image streams this is cumbersome
  - Build from known bases for security
- [ ] Review: https://github.com/argoproj/argocd-example-apps/blob/master/plugins/kustomized-helm/README.md
- [ ] Review: https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#_helmchartinflationgenerator
- [ ] Review: AWS user security. Limit access to the OCP provisioner account (reassign `Administrator' role to something limited)
- [ ] simplify / make generic machineset creation function
