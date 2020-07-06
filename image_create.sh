#!/bin/bash

export DOCKER_IMAGE_NAME=vyos-rolling
export DATA_DIR=$(mktemp -d /tmp/vyos_XXXXXX)
if [ -d $DATA_DIR ];then
    cd $DATA_DIR
    export RELEASES=$(mktemp /tmp/GEN_DOCKER_XXXXXX)
    w3m -dump 'https://downloads.vyos.io/?dir=rolling/current/amd64' > $RELEASES
    export REL_DATE=$(cat $RELEASES |tail -n 13|head -1|sed -re 's/.*vyos.*-rolling-(.*)-amd.*/\1/g')
    export REL_NAME=$(cat $RELEASES |tail -n 13|head -1|sed -re 's/.*(vyos.*iso).*/\1/g')

    wget -O vyos.iso https://downloads.vyos.io/rolling/current/amd64/${REL_NAME}

    mkdir rootfs unsquashfs
    mount -o loop vyos.iso rootfs/

    unsquashfs -f -d unsquashfs/ rootfs/live/filesystem.squashfs

    tar --exclude=etc/systemd/system/multi-user.target.wants/acpid.service \
        --exclude=etc/systemd/system/multi-user.target.wants/atop.service \
        --exclude=etc/systemd/system/multi-user.target.wants/atopacct.service \
        --exclude=etc/systemd/system/multi-user.target.wants/console-setup.service \
        --exclude=etc/systemd/system/multi-user.target.wants/hyperv-daemons.hv-fcopy-daemon.service \
        --exclude=etc/systemd/system/multi-user.target.wants/hyperv-daemons.hv-kvp-daemon.service \
        --exclude=etc/systemd/system/multi-user.target.wants/hyperv-daemons.hv-vss-daemon.service \
        --exclude=etc/systemd/system/multi-user.target.wants/open-vm-tools.service \
        --exclude=etc/systemd/system/serial-getty@ttyS0.service \
        --exclude=etc/systemd/system/getty.target.wants/getty@tty1.service \
        --exclude=etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service \
        --exclude=etc/systemd/system/xe-guest-utilities.service \
        -C unsquashfs -c . | docker import - ${DOCKER_IMAGE_NAME}:${REL_DATE}

    umount ${DATA_DIR}/rootfs
    rm -rf ${DATA_DIR} ${RELEASES}
    echo "To run this image:"

    cat << EOD
docker run --name vyos-in-docker --rm -d \\
    -v /_PATH_TO_/vyos-config:/opt/vyatta/etc/config \\
    -v /lib/modules/:/lib/modules:ro \\
    --privileged ${DOCKER_IMAGE_NAME}:${REL_DATE}  /sbin/init 
EOD

else
    echo "mktep failed wtf?"
fi