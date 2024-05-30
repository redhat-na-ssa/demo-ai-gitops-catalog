# syntax=docker/dockerfile:1.3-labs
# https://github.com/redhat-developer/web-terminal-tooling
ARG IMAGE_NAME=registry.access.redhat.com/ubi9/ubi
FROM ${IMAGE_NAME}

USER 0

# install: common tools
RUN dnf repolist && \
    dnf update -y && \
    dnf install -y \
      openssh-clients rsync \
      # compression tools
      bzip2 zip xz \
      # bash completion tools
      bash-completion ncurses pkgconf-pkg-config findutils \
      # zsh
      zsh \
      # terminal-based editors
      less vi vim nano \
      # misc tools
      httpd-tools \
      # developer tools
      diffutils curl-minimal wget tar git git-lfs procps jq && \
    dnf clean all && \
    rm -rf /var/cache/yum/*

ENV WRAPPER_BINARIES=/wto/bin
ENV BIN_PATH=/usr/local/bin
ENV PATH="${WRAPPER_BINARIES}:${PATH}"

COPY src/etc/initial_config /etc/skel
COPY src/etc/wtoctl src/etc/wtoctl_help.sh src/etc/wtoctl_jq.sh "${BIN_PATH}/"
COPY src/etc/cli-wrappers/* "${WRAPPER_BINARIES}/"
COPY src/etc/get-tooling-versions.sh "${WRAPPER_BINARIES}/"

# install: entrypoint
COPY --chown=0:0 entrypoint.sh /

# install: cli tools
ADD tools-x86_64.tgz /

# setup: user
RUN \
    # setup $PS1 prompt
    sed -i '/^export PS1=.*/d' /etc/skel/.bashrc && \
    echo "export PS1='\W \`git branch --show-current 2>/dev/null | sed -r -e \"s@^(.+)@\(\1\) @\"\`$ '" >> /etc/skel/.bashrc && \
    # copy global git configuration to user config
    cp /etc/gitconfig /etc/skel/.gitconfig && \
    useradd -u 1001 \
      -G wheel,root \
      -d /home/user \
      --shell /bin/bash \
      -m user && \
    # Set permissions on /etc/passwd and /home to allow users to write
    chgrp -R 0 /home && \
    chmod -R g=u /etc/passwd /etc/group /home && \
    chmod +x /entrypoint.sh && \
    chmod g+w /wto/bin && \
    get-tooling-versions.sh > /tmp/installed_tools.txt

ARG YOLO_URL=https://raw.githubusercontent.com/redhat-na-ssa/demo-ai-gitops-catalog/main/scripts/library/term.sh
RUN bash -c 'cd /home/user; . <(curl -sL '"${YOLO_URL}"') && term_bashrc /etc/skel/.bashrc'

USER 1001
ENV HOME=/home/user

WORKDIR ${HOME}
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["sleep", "infinity"]

# labels for container catalog
LABEL summary="Web Terminal - tooling container" \
      description="Web Terminal - tooling container" \
      io.k8s.display-name="Web Terminal - tooling container" \
      io.openshift.expose-services=""
