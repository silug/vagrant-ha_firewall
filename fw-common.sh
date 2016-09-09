#!/bin/bash

if [ -d /vagrant/sync ] ; then
    vagrantsync=/vagrant/sync
elif [ -d /home/vagrant/sync ] ; then
    vagrantsync=/home/vagrant/sync
else
    echo "Can't find sync directory!" >&2
    exit 1
fi

sudo yum -y install keepalived conntrack-tools perl-Data-Dumper
sudo yum -y install http://ftp.kspei.com/pub/kspei/add-ons/el/6/noarch/genfw-1.47-1.el6.noarch.rpm

sudo sed -i -e '/^DEFROUTE=/d;$aDEFROUTE=no' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i -e '/^PEERROUTES=/d;$aPEERROUTES=no' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i -e '/^DEVICE=/d;$aDEVICE=eth0' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i -e '$aGATEWAY=192.168.10.1' /etc/sysconfig/network-scripts/ifcfg-eth1

sudo systemctl stop NetworkManager.service
sudo systemctl disable NetworkManager.service

[ -f /var/run/dhclient-eth0.pid ] && sudo pkill dhclient
sudo ip route delete default

sudo chkconfig network on
sudo systemctl restart network.service

sudo $vagrantsync/keepalived.conf.sh "$@"

sudo systemctl enable keepalived.service
sudo systemctl start keepalived.service

sudo $vagrantsync/conntrackd.conf.sh

sudo systemctl enable conntrackd
sudo systemctl start conntrackd

sudo cp -fv $vagrantsync/*.rules /etc/sysconfig/genfw/rules.d/
sudo chkconfig firewall on
sudo systemctl start firewall.service

sudo cp -fv $vagrantsync/ip_forward.conf /etc/sysctl.d/
sudo sysctl -w net.ipv4.ip_forward=1
