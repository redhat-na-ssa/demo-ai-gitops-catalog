# Data Science

## Recommendations

- Data sets as container images
    - Use a container to store your data set
    - Serve via `http` protocol - `s3`, `webdav`
        - `minio`, `rclone serve`, `httpd`
  - Push to public repo (`quay.io`, `ghcr.io`)

TODO

- Build an example of containerizing a data set

```
RC_USER=admin
RC_PASS=rclone

cat > rclone.conf <<CONFIG
[local]
type = local
CONFIG

podman run \
  -it \
  --rm \
  -v $(pwd):/data \
  -p 8080:8080 \
  docker.io/rclone/rclone \
    rcd \
    --config /tmp/rclone.conf \
    --rc-web-gui \
    --rc-addr :8080 \
    --rc-user ${RC_USER} \
    --rc-pass ${RC_PASS}
```
