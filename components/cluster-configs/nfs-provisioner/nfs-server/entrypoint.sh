#!/bin/bash

start(){
    # prepare /etc/exports
    echo "/data *(rw,fsid=0,insecure,no_root_squash)" >> /etc/exports

    # start rpcbind if it is not started yet
    if ! /usr/sbin/rpcinfo 127.0.0.1 > /dev/null; then
       echo "Starting rpcbind"
       /usr/sbin/rpcbind -w
    fi

    mount -t nfsd nfsd /proc/fs/nfsd

    # -N 4.x: disable NFSv4
    # -V 3: enable NFSv3
    /usr/sbin/rpc.mountd -V 3 -N 4 -N 4.1

    /usr/sbin/exportfs -r
    # -G 10 to reduce grace time to 10 seconds (the lowest allowed)
    /usr/sbin/rpc.nfsd -G 10 -N 2 -V 3 -N 4 -N 4.1 2
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
