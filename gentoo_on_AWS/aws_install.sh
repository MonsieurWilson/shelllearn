#!/bin/bash

# ignore signal
trap "" HUP ABRT

# global variables
PROGRAM=$(basename -s .sh $0)
LOG_FILE=/tmp/${PROGRAM}.log

echo "------------------------------"
echo "Source environment"
source /etc/profile
export PS1="(chroot) $PS1"
passwd root <<EOF >> ${LOG_FILE} 2>&1
nsfocus
nsfocus
EOF

echo "-------------------------------"
echo "Modifying emerge configuration"
echo 'MAKEOPTS="-j2"' >> /etc/portage/make.conf
echo 'GENTOO_MIRRORS="http://mirrors.163.com/gentoo/"' >> /etc/portage/make.conf

echo "-------------------------------"
echo "Installing dependicies"
emerge vim >> ${LOG_FILE} 2>&1
emerge =sys-devel/gcc-4.4.7 >> ${LOG_FILE} 2>&1
# emerge-webrsync >> ${LOG_FILE} 2>&1
# emerge  --update --deep --newuse @world >> ${LOG_FILE} 2>&1

echo "-------------------------------"
echo "Setting timezone"
echo "Asia/Shanghai" >> /etc/timezone
emerge --config sys-libs/timezone-data

echo "-------------------------------"
echo "Installing pci utils"
emerge sys-apps/pciutils >> ${LOG_FILE} 2>&1
# emerge =sys-kernel/gentoo-sources-3.10.95

echo "-------------------------------"
echo "Networking configuration"
emerge --noreplace net-misc/netifrc
# define your own network!
# echo 'config_eth0="10.24.67.5 netmask 255.255.0.0"' > /etc/conf.d/net
# echo 'routes_eth0="default gw 10.24.255.254"' >> /etc/conf.d/net
(cd /etc/init.d/ && ln -s net.lo net.eth0)
rc-update add net.eth0 default
rc-update add sshd default
# DO NOT forget modifying the /etc/ssh/sshd_config to permit the root to login
sed -i -e 's/^\(PermitRootLogin\).*/\1 yes/' /etc/ssh/sshd_config

echo "-------------------------------"
echo "Installing genkernel and grub2"
emerge sys-kernel/genkernel >> ${LOG_FILE} 2>&1
emerge sys-boot/grub:2 >> ${LOG_FILE} 2>&1

echo "-------------------------------"
echo "Next you should do by yourself"
echo "make menuconfig"
echo "make && make modules_install && make install"
echo "genkernel --install initramfs"
echo "grub-install /dev/*"
echo "grub-mkconfig -o /boot/grub/grub.cfg"
