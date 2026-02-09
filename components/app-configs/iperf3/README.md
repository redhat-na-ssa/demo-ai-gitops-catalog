# OpenShift Network Performance Test

## Links

- https://access.redhat.com/articles/5233541

## Local host test

*NOTE: Tested with RHEL / Podman*

```sh
# build
podman build -t netperf .

# local network bridge
podman network create local

# host run
podman run -d --rm \
    --network local \
    --name host netperf

# client run
podman run -it --rm \
    --network local \
    --name client netperf iperf3 -c host
```

## OpenShift / k8s Deployment

```sh
iperf3 -c localhost
```

```sh
iperf3 -c <host pod ip>
```

- [Dockerfile](Dockerfile)
- [Pod](pod.yaml)
- [OpenShift Build Config](build-config.yaml)
