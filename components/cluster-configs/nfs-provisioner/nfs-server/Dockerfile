ARG BASE_IMAGE=quay.io/fedora/fedora-minimal:44
# ARG BASE_IMAGE=registry.access.redhat.com/ubi9/ubi

# hadolint ignore=DL3006
FROM ${BASE_IMAGE}

# hadolint ignore=DL3033
RUN yum install -y /usr/bin/ps nfs-utils && \
    yum clean all

RUN cat > /usr/local/bin/entrypoint.sh <<EOF
#!/bin/bash

start(){
    # prepare /etc/exports
    echo "/data *(rw,fsid=0,insecure,no_root_squash)" >> /etc/exports

    # start rpcbind if it is not started yet
    if ! /usr/sbin/rpcinfo 127.0.0.1 > /dev/null; then
       echo "Starting rpcbind"
       /usr/sbin/rpcbind -w
    fi

    # mount -t nfsd nfsd /proc/fs/nfsd

    # -N 4.x: disable NFSv4
    # -V 3: enable NFSv3
    /usr/sbin/rpc.mountd -V 3 -N 4 -N 4.1

    /usr/sbin/exportfs -r
    # -G 10 to reduce grace time to 10 seconds (the lowest allowed)
    /usr/sbin/rpc.nfsd -G 10 -V 3 -N 4 -N 4.1 2
    /usr/sbin/rpc.statd --no-notify
    echo "NFS started"
}

stop(){
    echo "Stopping NFS"

    /usr/sbin/rpc.nfsd 0
    /usr/sbin/exportfs -au
    /usr/sbin/exportfs -f

    kill "$(pidof rpc.mountd)"
    umount /proc/fs/nfsd
    echo > /etc/exports
    exit 0
}


trap stop TERM

start

sleep infinity
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /data

EXPOSE 2049/tcp \
        20048/tcp \
        111/tcp \
        111/udp

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
