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
