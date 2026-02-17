# ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi
# ARG BASE_IMAGE=quay.io/centos/centos:stream9
ARG BASE_IMAGE=quay.io/fedora/fedora-minimal:43

# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

# hadolint ignore=DL3033
RUN yum install -y iperf3 && \
    yum clean all

EXPOSE 5201

# CMD trap : TERM INT; sleep infinity & wait
# hadolint ignore=DL3025
CMD iperf3 -s
