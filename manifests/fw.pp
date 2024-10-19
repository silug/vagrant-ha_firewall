# @summary Configure a HA firewall
# @param packages Helper packages
# @param zones Firewall zones to manage
# @param if_all Array of interfaces
# @param if_mgmnt Management interface
# @param if_external External interface
# @param if_internal Internal interface
# @param gateway Gateway IP address
# @param exposed_ip External NAT IP address
class ha_firewall::fw (
  Array $packages               = [
    'iptraf-ng',
    'tcpdump',
    'traceroute',
  ],
  Array $zones                  = [
    'external',
    'internal',
  ],
  Array[String]    $if_all      = $facts['networking']['interfaces'].filter |$iface| {
    $iface[1]['mac'] != undef and $iface[1]['ip'] != undef
  }.keys,
  Optional[String] $if_mgmnt    = $if_all[0],
  String           $if_external = $if_all[-2],
  String           $if_internal = $if_all[-1],
  String           $gateway     = $facts['networking']['interfaces'][$if_internal]['ip'].regsubst('\.\d+$', '.1'),
  String           $exposed_ip  = $facts['networking']['interfaces'][$if_external]['ip'].regsubst('\.\d+$', '.254'),
) {
  ###
  # Configure the firewall
  ###
  include firewalld

  $zones.each |$zone| {
    firewalld_rich_rule { "${zone}-vrrp":
      ensure   => present,
      zone     => $zone,
      protocol => 'vrrp',
      action   => 'accept',
    }
  }

  firewalld_direct_rule { 'NAT outbound traffic':
    ensure        => present,
    inet_protocol => 'ipv4',
    table         => 'nat',
    chain         => 'POSTROUTING',
    priority      => 0,
    args          => "-o ${if_external} -j SNAT --to ${exposed_ip}",
  }

  firewalld_direct_rule { 'conntrackd':
    ensure        => present,
    inet_protocol => 'ipv4',
    table         => 'filter',
    chain         => 'INPUT',
    priority      => 0,
    args          => "-o ${if_mgmnt} -p udp --dport 3780 -d 225.0.0.50 -j ACCEPT",
  }

  ###
  # Configure keepalived
  ###
  class { 'keepalived':
    vrrp_sync_group => {
      'group1'             => {
        'group' => [
          'external1',
          'internal1',
        ],
        notify_script_master => '/usr/local/sbin/primary-backup.sh primary',
        notify_script_backup => '/usr/local/sbin/primary-backup.sh backup',
        notify_script_fault  => '/usr/local/sbin/primary-backup.sh fault',
      },
    },
    vrrp_instance   => {
      'external1' => {
        'interface'         => $if_external,
        'state'             => 'MASTER',
        'virtual_router_id' => 1,
        'priority'          => 100,
        'advert_int'        => 1,
        'auth_type'         => 'PASS',
        'auth_pass'         => 'lh62V.bF', # FIXME - Hard-coded password.
        'virtual_ipaddress' => $exposed_ip,
        'garp_master_delay' => 1,
      },
      'internal1' => {
        'interface'         => $if_internal,
        'state'             => 'MASTER',
        'virtual_router_id' => 2,
        'priority'          => 100,
        'advert_int'        => 1,
        'auth_type'         => 'PASS',
        'auth_pass'         => 'lh62V.bF', # FIXME - Hard-coded password.
        'virtual_ipaddress' => $gateway,
        'garp_master_delay' => 1,
      },
    },
  }

  ###
  # Configure conntrackd
  ###
  class { 'conntrackd':
    protocol               => 'Multicast',
    interface              => $if_internal,
    ipv4_address           => '225.0.0.50',
    disable_external_cache => 'On',
    commit_timeout         => 0,
    ipv4_interface         => $facts['networking']['interfaces'][$if_internal]['ip'],
  }

  ###
  # Add some helpful packages
  ###
  $packages.each |$package| {
    package { $package:
      ensure => installed,
    }
  }

  ###
  # Configure the network
  ###
  if $if_mgmnt {
    network_config { $if_mgmnt:
      ensure  => present,
      method  => 'dhcp',
      onboot  => 'yes',
      options => {
        'TYPE'                => 'Ethernet',
        'HWADDR'              => $facts['networking']['interfaces'][$if_mgmnt]['mac'],
        'PERSISTENT_DHCLIENT' => 'yes',
        'DEFROUTE'            => 'no',
        'PEERROUTES'          => 'no',
        'NM_CONTROLLED'       => 'yes',
        'ZONE'                => 'trusted',
      },
      notify  => Service['NetworkManager'],
    }
  }

  network_config { $if_internal:
    ensure    => present,
    method    => 'static',
    onboot    => 'yes',
    ipaddress => $facts['networking']['interfaces'][$if_internal]['ip'],
    netmask   => $facts['networking']['interfaces'][$if_internal]['netmask'],
    options   => {
      'TYPE'          => 'Ethernet',
      'HWADDR'        => $facts['networking']['interfaces'][$if_internal]['mac'],
      'GATEWAY'       => $gateway,
      'DEFROUTE'      => 'yes',
      'NM_CONTROLLED' => 'yes',
      'ZONE'          => 'internal',
    },
    notify    => Service['NetworkManager'],
  }

  network_config { $if_external:
    ensure    => present,
    method    => 'static',
    onboot    => 'yes',
    ipaddress => $facts['networking']['interfaces'][$if_external]['ip'],
    netmask   => $facts['networking']['interfaces'][$if_external]['netmask'],
    options   => {
      'TYPE'          => 'Ethernet',
      'HWADDR'        => $facts['networking']['interfaces'][$if_external]['mac'],
      'DEFROUTE'      => 'no',
      'NM_CONTROLLED' => 'yes',
      'ZONE'          => 'external',
    },
    notify    => Service['NetworkManager'],
  }

  service { 'network':
    ensure => stopped,
    enable => false,
  }

  service { 'NetworkManager':
    ensure => running,
    enable => true,
  }

  ###
  # Enable IP forwarding
  ###
  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }
}
