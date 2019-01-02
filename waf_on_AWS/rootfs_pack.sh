#!/bin/sh

# redirect stdout & stderr
#exec

# set xtrace
#set -x

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

# void disk_check(char *disk, int size)
disk_check()
{
    [ $# -ne 2 ] && die $? "Missing arguments."

    DISK=$1
    SIZE=$2

    [ -b /dev/${DISK} ] || die $? "Disk ${DISK} not exist, please check."
    [ -f /sys/block/${DISK}/size ] && {
        [ $(cat /sys/block/${DISK}/size) -gt ${SIZE} ] || {
            die $? "Disk ${DISK} size too small, please check."
        }
    }
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

stop()
{
    echo "Stop WAF service"
    /opt/nsfocus/bin/stop.py
    sleep 5
    echo "Stop running processes"
    killall python
    killall self_learn
    killall wlManager
    killall syslog-ng
    killall qpidd
    killall wlogd
    killall klogd
    killall -9 plat_srv
    dmesg -c &> /dev/null
}

stop

# echo "Check mounted devices"
# MOUNTED_PATH=$(mount -l | grep /dev/mapper | grep -v root | awk '{print $3}')
# if [ -n "$MOUNTED_PATH" ];then
#     echo "Umount devices"
#     umount $MOUNTED_PATH
# fi


echo "Packing rootfs files from local environment."
tar --exclude-from=rootfs_ex.list --files-from=rootfs.list -zcf /opt/data/rootfs.gz

