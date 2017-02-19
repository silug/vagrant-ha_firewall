#!/bin/bash

if [ -d /vagrant/sync ] ; then
    vagrantsync=/vagrant/sync
elif [ -d /home/vagrant/sync ] ; then
    vagrantsync=/home/vagrant/sync
elif [ -d /vagrant ] ; then
    vagrantsync=/vagrant
else
    echo "Can't find sync directory!" >&2
    exit 1
fi

sudo yum -y install keepalived conntrack-tools

# For demo/diagnostic purposes
sudo yum -y install iptraf-ng tcpdump

sudo systemctl enable firewalld.service
sudo systemctl start firewalld.service

sudo firewall-cmd --zone=external \
  --add-rich-rule='rule protocol value="vrrp" accept' --permanent
sudo firewall-cmd --zone=internal \
  --add-rich-rule='rule protocol value="vrrp" accept' --permanent

sudo firewall-cmd --permanent --direct \
    --add-rule ipv4 nat POSTROUTING 0 -o eth1 -j SNAT --to 192.168.10.254

sudo firewall-cmd --permanent --direct \
    --add-rule ipv4 filter INPUT 0 -i eth0 -p udp --dport 3780 -d 225.0.0.50 -j ACCEPT

sudo firewall-cmd --reload

sudo sed -i \
    -e '/^DEFROUTE=/d;$aDEFROUTE=no' \
    -e '/^PEERROUTES=/d;$aPEERROUTES=no' \
    -e '/^DEVICE=/d;$aDEVICE=eth0' \
    -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
    -e '/^ZONE=/d;$aZONE=trusted' \
    /etc/sysconfig/network-scripts/ifcfg-eth0

sudo sed -i \
    -e '$aGATEWAY=192.168.10.1' \
    -e '/^DEFROUTE=/d;$aDEFROUTE=yes' \
    -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
    -e '/^BOOTPROTO=/d;$aBOOTPROTO=static' \
    -e '/^ZONE=/d;$aZONE=external' \
    /etc/sysconfig/network-scripts/ifcfg-eth1

sudo sed -i \
    -e '/^DEFROUTE=/d;$aDEFROUTE=no' \
    -e '/^NM_CONTROLLED=/d;$aNM_CONTROLLED=yes' \
    -e '/^BOOTPROTO=/d;$aBOOTPROTO=static' \
    -e '/^ZONE=/d;$aZONE=internal' \
    /etc/sysconfig/network-scripts/ifcfg-eth2

sudo systemctl stop network.service
sudo systemctl stop NetworkManager.service
[ -f /var/run/dhclient-eth0.pid ] && sudo pkill dhclient
sudo systemctl start NetworkManager.service

sudo $vagrantsync/keepalived.conf.sh "$@"

sudo systemctl enable keepalived.service
sudo systemctl start keepalived.service

sudo $vagrantsync/conntrackd.conf.sh

sudo systemctl enable conntrackd
sudo systemctl start conntrackd

sudo cp -fv $vagrantsync/ip_forward.conf /etc/sysctl.d/
sudo sysctl -w net.ipv4.ip_forward=1
