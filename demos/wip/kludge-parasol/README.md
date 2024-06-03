# Kludge the parasol insurance demo to work

This demo is hard to reproduce consistently due to gaps in the configuration and lack of prerequisites documented

The scripting is also difficult to follow and repair - lots of glue code

## Issues

- Deployment `vllm` is broken
  - `quay.io/rh-aiservices-bu/vllm-openai-ubi9:0.4.0` is broken
  - See https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/llm-servers/vllm
  - See https://quay.io/repository/rh-aiservices-bu/vllm-openai-ubi9
- Error: `Pipeline version cannot be rendered`
  - Tekton pipelines are no longer supported in the GUI

## Quick Start

```sh
# setup base cluster
apply_firmly clusters/default
# setup base rhoai
apply_firmly demos/rhoai-nvidia-gpu-autoscale

# setup demo things
apply_firmly components/configs/kustomized/rhoai-config
apply_firmly demos/wip/kludge-parasol
```

## Links

- https://github.com/rh-aiservices-bu/parasol-insurance
- https://github.com/rh-aiservices-bu/insurance-claim-processing
