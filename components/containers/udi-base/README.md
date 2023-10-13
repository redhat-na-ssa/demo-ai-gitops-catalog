# Info

Dependencies can be created as container layers building upon a base image.

Specifically we are installing dependencies for Python on a udi-cuda base.

## Quickstart

```
cd containers/udi/ubi9

BASE_IMAGE=localhost/udi:ubi9

podman build . \
  -t ${BASE_IMAGE}

cd ../../python/ubi9/3.11
podman build . \
  -t localhost/udi:python39 \
  --build-arg IMAGE_NAME=${BASE_IMAGE}
```

## Links

- [Dev Spaces - Developer Images](https://github.com/devfile/developer-images)

## Notes
