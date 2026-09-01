ARG IMAGE_NAME=registry.access.redhat.com/ubi9/ubi
FROM ${IMAGE_NAME}

# hadolint ignore=DL3002
USER 0

COPY test-cve-2026-31431.py /usr/local/bin

USER 1001

CMD ["python3", "/usr/local/bin/test-cve-2026-31431.py"]
