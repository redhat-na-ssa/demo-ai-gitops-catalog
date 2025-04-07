# Notes about install

Dump `helm` to `yaml`

```sh
helm template --output-dir './scratch' longhorn/longhorn -n longhorn-system -f values.yaml
```
