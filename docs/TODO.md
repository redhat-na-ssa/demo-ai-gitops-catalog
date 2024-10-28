# TODO Items

- [ ] add: increase storage for workers to 200 GB
- [ ] add: create example jupyter containers with ubi base
- [ ] add: scripted caching mirror registry
- [ ] add: openldap w/ idp and ldapsync example
- [ ] add: image streams for custom jupyter notebooks
  - https://github.com/opendatahub-io-contrib/workbench-images
  - Without image streams this is cumbersome
  - Build from known bases for security
- [ ] Review: AWS user security. Limit access to the OCP provisioner account (reassign `Administrator' role to something limited)

## Notes Dump

- Most people try to use the local shell (mac users) - zsh
- Users not clear what options are available for bootstrap
- Add image of what web term icon looks like in top right
- The quick start is not easy to read
- The automation is too easy for users
  - need to be able to explain to a customer
  - need to be able to understand how it works on a basic level
- Explain what it means to setup a default cluster
- Tree defining the repo dir structure could help navigation

## Review Links

- https://github.com/argoproj/argocd-example-apps/blob/master/plugins/kustomized-helm/README.md
- https://kubectl.docs.kubernetes.io/references/kustomize/builtins/#_helmchartinflationgenerator
- https://github.com/viaduct-ai/kustomize-sops
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/bootstrap/argocd.yaml#L86
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/bootstrap/kustomization.yaml#L8
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/applications/alertmanager.yaml#L21
- https://github.com/rh-dttl-edge-virt-demo/edge-virt/blob/main/encrypt-chart-secrets.sh
- https://krew.sigs.k8s.io/docs/user-guide/setup/install/#bash