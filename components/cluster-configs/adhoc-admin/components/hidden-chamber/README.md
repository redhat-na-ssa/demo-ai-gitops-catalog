# Hidden Chamber

```sh
# provide temporary admin via a token
TOKEN=$(oc -n adhoc-admin \
  exec deploy/sleeper-admin-0 -- oc whoami -t)

oc login --token $TOKEN
```
