# @summary Build a HA firewall pair
# @param targets The targets to run on.
plan ha_firewall (
  TargetSpec $targets = 'all',
) {
  apply_prep($targets)
  apply($targets) {
    if $facts['hostname'] =~ /^fw\d/ {
      include ha_firewall::fw
    } else {
      include ha_firewall::client
    }
  }
}
