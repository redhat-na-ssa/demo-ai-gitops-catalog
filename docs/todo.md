# TODO Items

- [ ] Add: scripted caching mirror registry
- [ ] Add: openldap w/ idp and ldapsync example
- [ ] Review: AWS user security. Limit access to the OCP provisioner account (reassign `Administrator` role to something limited)

## Notes Dump

- Most people try to use the local shell
    - Mac - `zsh`
    - Win - `ps` *(who are we kidding, enterprise customers don't use powershell*)
- Users not clear what options are available for bootstrap
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
- https://labguides.readthedocs.io/en/latest/ocp/ocp.html
