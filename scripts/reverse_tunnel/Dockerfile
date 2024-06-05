FROM registry.access.redhat.com/ubi9/ubi:9.4

RUN dnf upgrade -y && \
    dnf install -y bind-utils openssh-clients which && \
    dnf clean all && \
    ssh -V

USER 1001

COPY reverse_tunnel.sh /app/

WORKDIR /app
VOLUME /config

ENV APP_PATH=/app \
    SSH_KEY=/config/id_ed25519 \
    HOME=/tmp

ENTRYPOINT [ "/app/reverse_tunnel.sh" ]
