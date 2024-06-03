# Kludge the parasol insurance demo to work

This demo is hard to reproduce consistently due to gaps in the configuration and lack of prerequisites documented

The scripting is also difficult to follow and repair - lots of glue code

## Quick Start

```sh
apply_firmly demos/rhoai
apply_firmly components/configs/kustomized/rhoai-config
apply_firmly demos/wip/kludge-parasol
```

## Links

- https://github.com/rh-aiservices-bu/parasol-insurance
- https://github.com/rh-aiservices-bu/insurance-claim-processing
