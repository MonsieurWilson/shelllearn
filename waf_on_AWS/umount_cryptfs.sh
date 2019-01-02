#!/bin/bash

APP=umount_cryptfs

umount /mnt/waf/
umount /mnt/waf/boot/
umount /mnt/waf/license/
umount /mnt/waf/opt/nsfocus/
umount /mnt/waf/opt/db/statinfo/
umount /mnt/waf/opt/db/loginfo/
umount /mnt/waf/opt/db/loginfoidx/
umount /mnt/waf/opt/log/
umount /mnt/waf/opt/data/

cryptsetup luksClose /dev/mapper/root
cryptsetup luksClose /dev/mapper/license
cryptsetup luksClose /dev/mapper/nsfocus
cryptsetup luksClose /dev/mapper/statinfo
cryptsetup luksClose /dev/mapper/loginfo
cryptsetup luksClose /dev/mapper/loginfoidx
cryptsetup luksClose /dev/mapper/log
cryptsetup luksClose /dev/mapper/data
