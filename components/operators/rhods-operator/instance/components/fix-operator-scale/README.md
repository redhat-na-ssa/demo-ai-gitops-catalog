# fix-operator-scale

## Purpose

This component is designed set the RHOAI operator to a sane number of `1` (not `3`) to avoid wasted resources and issues with leader election.

## Usage

This component can be added to a base by adding the `components` section to your overlay `kustomization.yaml` file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

components:
  - ../../components/fix-operator-scale
```
