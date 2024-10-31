# fix-dashboard-magic

## Purpose

This component is designed restart the RHOAI dashboard to avoid issues with features note being detected.

## Usage

This component can be added to a base by adding the `components` section to your overlay `kustomization.yaml` file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

components:
  - ../../components/fix-dashboard-magic
```
