#!/bin/bash

sudo sed -i -e '/^DEFROUTE=/d;$aDEFROUTE=no' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i -e '/^PEERROUTES=/d;$aPEERROUTES=no' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i -e '/^DEVICE=/d;$aDEVICE=eth0' /etc/sysconfig/network-scripts/ifcfg-eth0
sudo sed -i -e '$aGATEWAY=192.168.11.254' /etc/sysconfig/network-scripts/ifcfg-eth1

sudo systemctl stop NetworkManager.service
sudo systemctl disable NetworkManager.service

[ -f /var/run/dhclient-eth0.pid ] && sudo pkill dhclient
sudo ip route delete default

sudo chkconfig network on
sudo systemctl restart network.service
