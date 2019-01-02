#!/bin/bash

KEY_ROOT=/root/waf_on_AWS
WAF_DEVICE=
APP=mount_cryptfs

if [ "$#" -eq 1 ]; then
    WAF_DEVICE=$1
else
    echo "Usage: ${APP} <waf_device>"
    exit 1
fi

cryptsetup -d ${KEY_ROOT}/.key luksOpen /dev/${WAF_DEVICE}2 root
cryptsetup -d ${KEY_ROOT}/.key-license luksOpen /dev/${WAF_DEVICE}3 license
cryptsetup -d ${KEY_ROOT}/.key-nsfocus luksOpen /dev/${WAF_DEVICE}5 nsfocus
cryptsetup -d ${KEY_ROOT}/.key-hd luksOpen /dev/${WAF_DEVICE}6 statinfo
cryptsetup -d ${KEY_ROOT}/.key-hd luksOpen /dev/${WAF_DEVICE}7 loginfo
cryptsetup -d ${KEY_ROOT}/.key-hd luksOpen /dev/${WAF_DEVICE}8 loginfoidx
cryptsetup -d ${KEY_ROOT}/.key-hd luksOpen /dev/${WAF_DEVICE}9 log
cryptsetup -d ${KEY_ROOT}/.key-hd luksOpen /dev/${WAF_DEVICE}10 data

if [ ! -d /mnt/waf ]; then
    mkdir /mnt/waf
fi

mount /dev/mapper/root /mnt/waf/
mount /dev/${WAF_DEVICE}1 /mnt/waf/boot/
mount /dev/mapper/license /mnt/waf/license/
mount /dev/mapper/nsfocus /mnt/waf/opt/nsfocus/
mount /dev/mapper/statinfo /mnt/waf/opt/db/statinfo/
mount /dev/mapper/loginfo /mnt/waf/opt/db/loginfo/
mount /dev/mapper/loginfoidx /mnt/waf/opt/db/loginfoidx/
mount /dev/mapper/log /mnt/waf/opt/log/
mount /dev/mapper/data /mnt/waf/opt/data/
