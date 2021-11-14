# @summary Configura a client node
# @param if_all Array of interfaces
# @param if_mgmnt Management interface
# @param if_routed Interface used to route traffic
# @param gateway Gateway IP address
class ha_firewall::client (
  Array[String]    $if_all    = $facts['networking']['interfaces'].filter |$iface| {
    $iface[1]['mac'] != undef and $iface[1]['ip'] != undef
  }.keys,
  Optional[String] $if_mgmnt  = $if_all[0],
  String           $if_routed = $if_all[-1],
  String           $gateway   = $facts['networking']['interfaces'][$if_routed]['ip'].regsubst('\.\d+$', '.254'),
) {
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
      },
      notify  => Service['NetworkManager'],
    }
  }

  network_config { $if_routed:
    ensure    => present,
    method    => 'static',
    onboot    => 'yes',
    ipaddress => $facts['networking']['interfaces'][$if_routed]['ip'],
    netmask   => $facts['networking']['interfaces'][$if_routed]['netmask'],
    options   => {
      'TYPE'          => 'Ethernet',
      'HWADDR'        => $facts['networking']['interfaces'][$if_routed]['mac'],
      'GATEWAY'       => $gateway,
      'DEFROUTE'      => 'yes',
      'NM_CONTROLLED' => 'yes',
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
}
