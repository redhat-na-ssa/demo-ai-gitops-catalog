# OpenShift Gitops Components

The included components are intended to be common patching patterns used on top of the default OpenShift Gitops instance to configure additional features of ArgoCD.  Components are composable patches that can be added at the overlays layer on top of a base.

This repo currently contains the following components:

* [annotation-resource-tracking](annotation-resource-tracking)
* [application-controller-cluster-admin](application-controller-cluster-admin)
* [disable-pipelinerun-resourceexclusion](disable-pipelinerun-resourceexclusion)
* [edge-termination](edge-termination)
* [enable-notifications](enable-notifications)
* [gitops-admins](gitops-admins)
* [health-check-odf](health-check-odf)
* [health-check-olm](health-check-olm)
* [health-check-openshift-ai](health-check-openshift-ai)
* [health-check-openshift-builds](health-check-openshift-builds)
* [kustomize-build-enable-helm](kustomize-build-enable-helm)

## Usage

Components can be added to a base by adding the `components` section to your overlay `kustomization.yaml` file:

```sh
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

components:
  - ../../components/annotation-resource-tracking
  - ../../components/application-controller-cluster-admin
  - ../../components/disable-pipelinerun-resourceexclusion
  - ../../components/edge-termination
  - ../../components/enable-notifications
  - ../../components/gitops-admins
  - ../../components/health-check-odf
  - ../../components/health-check-olm
  - ../../components/health-check-openshift-ai
  - ../../components/health-check-openshift-builds
  - ../../components/kustomize-build-enable-helm
```
