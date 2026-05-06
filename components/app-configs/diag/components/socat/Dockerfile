# ARG BASE_IMAGE=quay.io/fedora/fedora-minimal:43
ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi

# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

# hadolint ignore=DL3033
RUN yum install -y socat && \
    yum clean all

EXPOSE 6666

# hadolint ignore=DL3025
CMD socat TCP4-LISTEN:6666,reuseaddr,fork -
# CMD trap : TERM INT; sleep infinity & wait
