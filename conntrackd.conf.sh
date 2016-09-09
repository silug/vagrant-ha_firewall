#!/bin/bash

localip="$( ip addr list eth0 | awk '($1 == "inet") { sub(/\/.*$/, "", $2); print $2 }' )"

cat > /etc/conntrackd/conntrackd.conf <<END
Sync {  
        Mode FTFW {
            DisableExternalCache On
        }

        Multicast {
                IPv4_address 225.0.0.50
                Group 3780
                IPv4_interface ${localip}
                Interface eth0
                SndSocketBuffer 1249280
                RcvSocketBuffer 1249280
                Checksum on
        }
}

General {
        Nice -20
        HashSize 32768
        HashLimit 131072
        LogFile on
        LockFile /var/lock/conntrack.lock
                
        UNIX {
                Path /var/run/conntrackd.ctl
                Backlog 20
        }

        NetlinkBufferSize 2097152
        NetlinkBufferSizeMaxGrowth 8388608

        Filter From Userspace {
                Protocol Accept {
                        TCP
                        SCTP
                        DCCP
                }

                Address Ignore {
                        IPv4_address 127.0.0.1 # loopback
                        IPv4_address 192.168.10.254 # virtual IP 1
                        IPv4_address 192.168.11.254 # virtual IP 2
                        IPv4_address 192.168.10.2
                        IPv4_address 192.168.11.2
                        IPv4_address 192.168.10.3
                        IPv4_address 192.168.11.3
                        IPv4_address ${localip} # dedicated link ip
                }

        }
}
END
