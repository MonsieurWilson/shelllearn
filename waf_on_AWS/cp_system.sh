#!/bin/sh

# redirect stdout & stderr
#exec

# set xtrace
# set -x

# global variables
KERNEL_VERSION=32628
HDDISK=xvda
LOG_FILE=/tmp/init_system.log
WAF_DISK=/mnt/waf
MOUNT_ROOT=/mnt/waf2
declare FSs=(
        ${HDDISK}3 key-license license /license
        ${HDDISK}5 key-nsfocus nsfocus /opt/nsfocus
        ${HDDISK}6 key-hd statinfo /opt/db/statinfo
        ${HDDISK}7 key-hd loginfo /opt/db/loginfo
        ${HDDISK}8 key-hd loginfoidx /opt/db/loginfoidx
        ${HDDISK}9 key-hd log /opt/log
        ${HDDISK}10 key-hd data /opt/data)

# ignore signal
trap "" INT QUIT TSTP

source /etc/profile

# void die(int error, char *message)
#
#    show a message and exit with error
die()
{
    local retval="${1:-0}"
    shift

    [ ${retval} == 0 ] && return
    echo " ** $*"
    exit ${retval}
}

# int is_mounted(device)
#
#     check whether device is mounted
is_mounted()
{
    for i in `cat /proc/mounts | cut -d' ' -f1`; do
        if [ "x$1" = "x$i" ]; then
            return 0
        fi
    done

    return 1
}


echo " >> Init hard disk."
dd if=/dev/urandom of=/dev/${HDDISK} bs=512 count=1 >>  ${LOG_FILE} 2>&1
die $? "Stage 1 failed."
fdisk /dev/${HDDISK} << EOF >>  ${LOG_FILE} 2>&1
n
p
1

+31M
n
p
2

+1G
n
p
3

+40M
n
e


n

+1.5G
n

+20G
n

+20G
n

+20G
n

+5G
n


w
EOF
die $? "Stage 2 failed."

echo " >> Mount rootfs and file system."
[ -d ${MOUNT_ROOT} ] || mkdir -p ${MOUNT_ROOT}

cryptsetup -q luksFormat /dev/${HDDISK}2 /root/waf_on_AWS/.key >>  ${LOG_FILE} 2>&1
cryptsetup -d /root/waf_on_AWS/.key luksOpen /dev/${HDDISK}2 root2 >>  ${LOG_FILE} 2>&1
mke2fs -j -L root /dev/mapper/root2  >> ${LOG_FILE} 2>&1
tune2fs -c 0 -C 0 -i 0 /dev/mapper/root2 >>  ${LOG_FILE} 2>&1
mount /dev/mapper/root2 ${MOUNT_ROOT} >> ${LOG_FILE} 2>&1
die $? "Mount rootfs failed."

mke2fs -j -L boot /dev/${HDDISK}1 >> ${LOG_FILE} 2>&1
tune2fs -c 0 -C 0 -i 0 /dev/${HDDISK}1 >>  ${LOG_FILE} 2>&1
[ -d ${MOUNT_ROOT}/boot ] || mkdir ${MOUNT_ROOT}/boot
mount /dev/${HDDISK}1 ${MOUNT_ROOT}/boot >>  ${LOG_FILE} 2>&1
die $? "Mount boot failed."

for ((i = 0; i < ${#FSs[*]}; i+=4 )); do
    dev=${FSs[${i}]}
    key=${FSs[$((i+1))]}
    name=${FSs[$((i+2))]}2
    mountpoint=${MOUNT_ROOT}${FSs[$((i+3))]}
    # [ "$#" != 0 -a ${name} == "license" ] && continue
    echo " >> Open device $((i/4))"
    cryptsetup -q luksFormat /dev/${dev} /root/waf_on_AWS/.${key} >>  ${LOG_FILE} 2>&1
    die $? "Stage 1, open device ${dev} failed."
    cryptsetup -d /root/waf_on_AWS/.${key} luksOpen /dev/${dev} ${name} >>  ${LOG_FILE} 2>&1
    die $? "Stage 2, open device ${dev} failed."
    mke2fs -j -L ${name} /dev/mapper/${name} >>  ${LOG_FILE} 2>&1
    die $? "Stage 3, open device ${dev} failed."
    tune2fs -c 0 -C 0 -i 0 /dev/mapper/${name} >>  ${LOG_FILE} 2>&1
    die $? "Stage 4, open device ${dev} failed."
    [ -d ${mountpoint} ] || mkdir -p ${mountpoint}
    mount /dev/mapper/${name} ${mountpoint} >>  ${LOG_FILE} 2>&1
    die $? "Stage 5, open device ${dev} failed."
done

echo " >> Copy system from WAF disk."
(cd ${WAF_DISK} && cp -rp bin cgroup cneos data dev dev.tgz etc lib lib32 lib64 license opt qemu root run sbin usr var ${MOUNT_ROOT})
mkdir ${MOUNT_ROOT}/{proc,sys,mnt}
(cd ${MOUNT_ROOT} && ln -s var/tmp tmp)

echo " >> Copy kernel and initrd."
if ! ls ${WAF_DISK}/boot/*${KERNEL_VERSION}* > /dev/null 2>&1; then
    echo "Warning: No kernel and initrd matches, skip."
else
    cp ${WAF_DISK}/boot/*${KERNEL_VERSION} ${MOUNT_ROOT}/boot
fi

echo " >> Install grub."
grub-install --boot-directory=${MOUNT_ROOT}/boot /dev/${HDDISK}
cp ${WAF_DISK}/boot/grub/grub.cfg ${MOUNT_ROOT}/boot/grub/

echo " >> Copy system successful."
