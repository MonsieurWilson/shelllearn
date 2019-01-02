#!/bin/sh
#
# This is a program to install the VWAF system given the system image, kernel and initrd.
# It will do these things automaticly:
# 1) Disk partitation
# 2) Partitation crypto
# 3) Unpack system image to the specific disk
# 4) Copy the WAF kernel and Initrd to the boot directory
# 4) Install boot loader and write configuration correctly
# 

# redirect stdout & stderr
#exec

# set xtrace
# set -x

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

# global variables
HDDISK=
ROOTFS_IMG_PATH=
PROGRAM=$(basename -s .sh $0)
LOG_FILE=/tmp/${PROGRAM}.log

if [ "$#" -eq 2 ]; then
    HDDISK=$1
    ROOTFS_IMG_PATH=$2
else
    echo "Usage: ${PROGRAM} <hd_disk> <rootfs_img_path>"
    echo "       <hd_disk>            block device file to unpack the rootfs image, such as sda vda xvda etc."
    echo "       <rootfs_img_path>    rootfs image path, such as /root/rootfs.gz."
    exit 1
fi


echo " >> Initializing hard disk ... "
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

+2G
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
die $? "Stage 2 fdisk failed."

echo " >> Mount rootfs and file system."
declare FSs=(
        ${HDDISK}3 key-license license /license
        ${HDDISK}5 key-nsfocus nsfocus /opt/nsfocus
        ${HDDISK}6 key-hd statinfo /opt/db/statinfo
        ${HDDISK}7 key-hd loginfo /opt/db/loginfo
        ${HDDISK}8 key-hd loginfoidx /opt/db/loginfoidx
        ${HDDISK}9 key-hd log /opt/log
        ${HDDISK}10 key-hd data /opt/data)
MOUNT_ROOT=/mnt/waf
if [ ! -d ${MOUNT_ROOT} ]; then
    mkdir -p ${MOUNT_ROOT}
fi

cryptsetup -q luksFormat /dev/${HDDISK}2 .key >>  ${LOG_FILE} 2>&1
cryptsetup -d .key luksOpen /dev/${HDDISK}2 root >>  ${LOG_FILE} 2>&1
mke2fs -j -L root /dev/mapper/root  >> ${LOG_FILE} 2>&1
tune2fs -c 0 -C 0 -i 0 /dev/mapper/root >>  ${LOG_FILE} 2>&1
mount /dev/mapper/root ${MOUNT_ROOT} >> ${LOG_FILE} 2>&1
die $? "Stage 3, mount root point failed."

for ((i = 0; i < ${#FSs[*]}; i+=4 )); do
    dev=${FSs[${i}]}
    key=${FSs[$((i+1))]}
    name=${FSs[$((i+2))]}
    mountpoint=${MOUNT_ROOT}${FSs[$((i+3))]}
    echo " >> Open device $((i/4))"
    cryptsetup -q luksFormat /dev/${dev} .${key} >>  ${LOG_FILE} 2>&1
    die $? "Stage 1, open device ${dev} failed."
    cryptsetup -d .${key} luksOpen /dev/${dev} ${name} >>  ${LOG_FILE} 2>&1
    die $? "Stage 2, open device ${dev} failed."
    mke2fs -j -L ${name} /dev/mapper/${name} >>  ${LOG_FILE} 2>&1
    die $? "Stage 3, open device ${dev} failed."
    tune2fs -c 0 -C 0 -i 0 /dev/mapper/${name} >>  ${LOG_FILE} 2>&1
    die $? "Stage 4, open device ${dev} failed."
    if [ ! -d ${mountpoint} ]; then
        mkdir -p ${mountpoint}
    fi
    mount /dev/mapper/${name} ${mountpoint} >>  ${LOG_FILE} 2>&1
    die $? "Stage 5, open device ${dev} failed."
done

echo " >> Unpack system image."
tar -C ${MOUNT_ROOT} -zxvf ${ROOTFS_IMG_PATH} >> ${LOG_FILE} 2>&1
die $? "Unpack system failed."

echo " >> Mount boot partition."
[ -d ${MOUNT_ROOT}/boot ] || mkdir -p ${MOUNT_ROOT}/boot
mke2fs -j -L boot /dev/${HDDISK}1 >> ${LOG_FILE} 2>&1
tune2fs -c 0 -C 0 -i 0 /dev/${HDDISK}1 >> ${LOG_FILE} 2>&1
mount /dev/${HDDISK}1 ${MOUNT_ROOT}/boot >> ${LOG_FILE} 2>&1
die $? "Mount boot partition failed."

# echo " >> Install grub and copy waf kernels."
# command cp -f {vmlinuz-64bit.waf,waf64.img} ${MOUNT_ROOT}/boot
# grub-install --boot-directory=${MOUNT_ROOT}/boot /dev/${HDDISK} >> ${LOG_FILE} 2>&1
# command cp -f grub.cfg ${MOUNT_ROOT}/boot/grub
# ROOTFS_UUID=$(blkid | awk -F '"' '/'${HDDISK}'2/{print $2}')
# sed -i '1,$s/${ROOTFS_UUID}/'${ROOTFS_UUID}'/' ${MOUNT_ROOT}/boot/grub/grub.cfg
# die $? "Install grub failed."

mkdir -m 1777 -p ${MOUNT_ROOT}/dev
[ -d ${MOUNT_ROOT}/cgroup/cpuset ] || mkdir -m 777 -p ${MOUNT_ROOT}/cgroup/cpuset
[ -d ${MOUNT_ROOT}/proc ] || mkdir ${MOUNT_ROOT}/proc
[ -d ${MOUNT_ROOT}/sys ] || mkdir ${MOUNT_ROOT}/sys
[ -d ${MOUNT_ROOT}/var ] || mkdir ${MOUNT_ROOT}/var
[ -d ${MOUNT_ROOT}/var/tmp ] || mkdir ${MOUNT_ROOT}/var/tmp
(cd ${MOUNT_ROOT} && ln -s var/tmp tmp)

echo " >> System initialized successfully."
