#!/bin/bash

sudo sed -i \
    -e '/^DEFROUTE=/d;$aDEFROUTE=no' \
    -e '/^PEERROUTES=/d;$aPEERROUTES=no' \
    -e '/^DEVICE=/d;$aDEVICE=eth0' \
    -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
    /etc/sysconfig/network-scripts/ifcfg-eth0

sudo sed -i \
    -e '$aGATEWAY=192.168.11.254' \
    -e '/^DEFROUTE=/d;$aDEFROUTE=yes' \
    -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
    -e '/^BOOTPROTO=/d;$aBOOTPROTO=static' \
    /etc/sysconfig/network-scripts/ifcfg-eth1

sudo systemctl stop network.service
sudo systemctl stop NetworkManager.service
[ -f /var/run/dhclient-eth0.pid ] && sudo pkill dhclient
sudo systemctl start NetworkManager.service
