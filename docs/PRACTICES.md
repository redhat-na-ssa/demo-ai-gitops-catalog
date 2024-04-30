# Recommended Practices (Draft)

Below are recommended practices or references.

## Building Demos

Common cli tools across platforms:

- `git`
- `bash`
- `oc` / `kubectl`
- `python` (v3)
  - `ansible`

Considerations

- ALWAYS **start** with a `README.md`
  - One sentence is ok
  - Ex: Title: Weather Toaster, Body: I want to build a toaster that controls the weather
  - ALWAYS commit to `git` - do you see what I did there? :)
  - Use a public `git` location - We can always rewrite (git) history to make it look perfect
- One click solutions - Ex: `scripts/bootstrap.sh`
  - Offer a solution that takes less than 5 minutes of user interaction to complete (your automation can take longer)
  - Exception: When you are building training into your demo
- Make friends / Collaborate - Have ~~strange people~~ others test your work
  - Regular peer reviews (short and frequent)
  - 3 days max between peer review
  - Goal: avoid *"it worked on my machine..."*
- Modular design - Build for reuse
  - *How can I make this easy for someone to reuse my work?*

Architecture

- Assume minimum privilege for the user / demo
  - Ex: user may only have access to namespace vs `cluster-admin`
  - Use appropriate role bindings (avoid admin)
- Use the minimum number of cli tools and dependencies
- Scripting - avoid complex functions (`bash`, `python`, `Makefile`)
  - Attempt to show commands for manual operations
  - Use functions for reusability
  - *Can I cut and paste?*

## Data Science

Recommendations

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
