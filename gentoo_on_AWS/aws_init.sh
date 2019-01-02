#!/bin/bash

# ignore signal
trap "" HUP ABRT

echo "---------------------------------"
echo "Change system"

MOUNT_ROOT="/mnt/gentoo"

[ -d /${MOUNT_ROOT} ] || mkdir /${MOUNT_ROOT}
mount -t proc proc /${MOUNT_ROOT}/proc
mount --rbind /sys /${MOUNT_ROOT}/sys
mount --rbind /dev /${MOUNT_ROOT}/dev
mount --make-rslave /${MOUNT_ROOT}/dev
mount --make-rslave /${MOUNT_ROOT}/sys
chroot /${MOUNT_ROOT} /bin/bash
