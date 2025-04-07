# Notes longhorn

Dump `helm` to `yaml`

```sh
# export helm into yaml
helm template --output-dir './scratch' longhorn/longhorn -n longhorn-system -f values.yaml

# move yaml into base
mv scratch/longhorn/templates/* base/
mv base/uninstall-job.yaml overlays/uninstall
```
