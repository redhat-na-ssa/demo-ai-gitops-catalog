# syntax=docker/dockerfile:1.3-labs
ARG IMAGE_NAME=registry.access.redhat.com/ubi9/ubi:9.4
FROM ${IMAGE_NAME}

# cherry picked from below
# https://github.com/devfile/developer-images/blob/main/base/ubi8/Dockerfile

# labels for container catalog
LABEL summary="devfile base developer image"
LABEL description="image with base developers tools"
LABEL io.k8s.display-name="devfile-developer-base"
LABEL io.openshift.expose-services=""

USER 0

# install: common tools
RUN dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    dnf install -y bash curl-minimal diffutils git git-lfs iproute jq less lsof man nano procps p7zip p7zip-plugins \
                   perl-Digest-SHA net-tools openssh-clients rsync socat time vim wget zip && \
                   dnf clean all && \
                   rm -rf /var/cache/yum/*

# install: other bins
RUN yum install -y libGL bash-completion && \
    yum clean all && \
    rm -rf /var/cache/yum/*

# install: oc,tkn
# todo: install cli tools during env init / not in container
ARG OC4_URL="https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz"
ARG TKN_URL="https://mirror.openshift.com/pub/openshift-v4/clients/pipeline/latest/tkn-linux-amd64.tar.gz"

RUN curl -sL "${OC4_URL}" | \
      tar -C /usr/local/bin -vzxf- oc kubectl && \
      /usr/local/bin/oc completion bash > /etc/bash_completion.d/oc && \
      echo "source /etc/bash_completion.d/oc" >> /etc/skel/.bashrc && \
    curl -sL "${TKN_URL}" | \
      tar -C /usr/local/bin -vzxf- --no-same-owner tkn && \
      /usr/local/bin/tkn completion bash > /etc/bash_completion.d/tkn && \
      echo "source /etc/bash_completion.d/tkn" >> /etc/skel/.bashrc

# install: entrypoint
COPY --chown=0:0 entrypoint.sh /

# setup: user
# hadolint ignore=SC2028
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
    chmod +x /entrypoint.sh

USER 1001
ENV HOME=/home/user
VOLUME /home/user

WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["sleep", "infinity"]
