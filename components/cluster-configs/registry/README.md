# Registry Notes

## `oc-mirror`

See https://github.com/openshift/oc-mirror

Mirror to Disk

```sh
oc-mirror -c ./isc.yaml file:///${PWD}/scratch/oc-mirror --v2
```

Disk to Mirror

```sh
oc-mirror -c ./isc.yaml --from file:///${PWD}/scratch/oc-mirror docker://registry:5000 --v2
```

Mirror to Mirror (`registry:5000`)

```sh
oc-mirror -c ./isc.yaml --workspace file:///${PWD}/scratch/oc-mirror docker://registry:5000 --v2
```
