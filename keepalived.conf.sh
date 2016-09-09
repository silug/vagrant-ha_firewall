#!/bin/bash

cat > /etc/keepalived/keepalived.conf <<END
vrrp_sync_group group1 {
    group {
        external1
        internal1
    }
}

vrrp_instance external1 {
    interface eth1
    state BACKUP
    virtual_router_id 1
    priority ${1}
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass ${2}
    }
    virtual_ipaddress {
        192.168.10.254/24 dev eth1
    }
    #nopreempt
    garp_master_delay 1
}

vrrp_instance internal1 {
    interface eth2
    state BACKUP
    virtual_router_id 2
    priority ${1}
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass ${2}
    }
    virtual_ipaddress {
        192.168.11.254/24 dev eth2
    }
    #nopreempt
    garp_master_delay 1
}
END
