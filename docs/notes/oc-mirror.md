# `oc-mirror`

See https://github.com/openshift/oc-mirror

`oc mirror` is used to aid in disconnected installs. It aids in mirroring container images and configuring
OpenShift to use a private registry.

## `oc-mirror` options

Setup config files

```sh
[ -d scratch ] || mkdir scratch
cp components/cluster-configs/registry/isc*.yaml scratch

REGISTRY=registry:5000
```

Mirror to Disk

```sh
oc-mirror -c scratch/isc.yaml file:///${PWD}/scratch/ocp4 --v2
```

Disk to Mirror

```sh
oc-mirror -c scratch/isc.yaml \
  --from file:///${PWD}/scratch/ocp4 \
  docker://"${REGISTRY}" --v2
```

Mirror to Mirror (`registry:5000`)

```sh
oc-mirror -c scratch/isc.yaml \
  --workspace file:///${PWD}/scratch/oc-mirror/ocp4 \
  docker://"${REGISTRY}" --v2
```

### Delete / Prune images

Stage 1

```sh
oc-mirror delete \
  -c scratch/isc-delete.yaml \
  --generate \
  --workspace file:///${PWD}/scratch/oc-mirror/ocp4 \
  --delete-id delete1 \
  docker://"${REGISTRY}" --v2
```

Stage 2

```sh
oc-mirror delete \
  --delete-yaml-file ${PWD}/scratch/oc-mirror/ocp4/working-dir/delete/delete-images-delete1.yaml \
  docker://"${REGISTRY}" --v2
```

## Hacks

`oc-mirror` (2025-08-13T02:09:59Z)

Pulling images times out at 10 minutes.

`oc-mirror --image-timeout 60m`

### Alternative

The following can create a `mapping.txt` file that can be used with `skopeo` to copy the images. This is **not** recommended - just notes of an insane mind.

Create `mapping.txt`

```sh
[ -d scratch ] || mkdir scratch
cp components/cluster-configs/registry/isc*.yaml scratch

REGISTRY=registry:5000

oc-mirror \
  -c scratch/isc.yaml \
  --workspace file:///${PWD}/scratch/oc-mirror/ocp4 \
  docker://"${REGISTRY}" \
  --v2 \
  --dry-run
```

Create `images.txt` - a list of images to copy

```sh
sed '
  s@^docker://@@g
  s@=docker://'"${REGISTRY}"'.*@@g
  /localhost/d' \
    scratch/oc-mirror/ocp4/working-dir/dry-run/mapping.txt | \
    sort -u > scratch/images.txt
```

Loop through `images.txt` - do stupid shell things

```sh
while read -r line
do
  skopeo copy docker://"${line}" \
    docker://"${REGISTRY}"/openshift \
    --authfile /run/user/1000/containers/auth.json

  sed -i "/${line##*/}/d" scratch/images.txt
done < scratch/images.txt
```

## Example MirrorSet

```yaml
---
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: idms-release-0
spec:
  imageDigestMirrors:
  - mirrors:
    - registry:5000/openshift/release
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  - mirrors:
    - registry:5000/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
---
apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata:
  name: itms-release-0
spec:
  imageTagMirrors:
  - mirrors:
    - registry:5000/openshift/release-images
    source: quay.io/openshift-release-dev/ocp-release
```

```yaml
---
apiVersion: config.openshift.io/v1
kind: ImageDigestMirrorSet
metadata:
  name: idms-generic-0
spec:
  imageDigestMirrors:
  - mirrors:
    - registry:5000/redhat-na-ssa
    source: ghcr.io/redhat-na-ssa
---
apiVersion: config.openshift.io/v1
kind: ImageTagMirrorSet
metadata:
  name: itms-generic-0
spec:
  imageTagMirrors:
  - mirrors:
    - registry:5000/redhat-na-ssa
    source: ghcr.io/redhat-na-ssa
```
