# Kludge the parasol insurance demo to work

This demo is:

- hard to reproduce consistently due to gaps in the source repo configuration
- lacks any useful documentation around deployment
- inconsistent in the use of automation
- costs a lot of $$$ to run / idle

## Issues

- Deployment `vllm` is only tested on aws gpu instance `g5.2xlarge`
  - See https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/llm-servers/vllm
  - See https://quay.io/repository/rh-aiservices-bu/vllm-openai-ubi9
- Error: `Pipeline version cannot be rendered` when using RHOAI version `2.9.1`
  - Tekton pipelines are no longer supported in the GUI

## Quick Start

```sh
# setup base cluster
apply_firmly clusters/default
# setup base rhoai
apply_firmly workshop/wip/parasol-insurance/00-prereqs
# setup demo
apply_firmly workshop/wip/parasol-insurance/01-setup
```

## Links

- [RHDP - Parasol Insurance Workshop](https://demo.redhat.com/catalog?item=babylon-catalog-prod/sandboxes-gpte.openshift-ai-unleashed.prod&utm_source=webapp&utm_medium=share-link) (private)
- [RHDP - Catalog](https://github.com/rhpds/agnosticv) (private)
  - `sandboxes-gpte/openshift-ai-unleashed`
- [GIT - Parasol Insurance](https://github.com/rh-aiservices-bu/parasol-insurance)
- [GIT - Insurance Claim (Related)](https://github.com/rh-aiservices-bu/insurance-claim-processing)
