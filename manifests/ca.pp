class pe_puppet::ca inherits pe_puppet::master {

  $autosign_servers = hiera('pe_puppet::ca::autosign_servers', undef)

  Ini_setting['pe_puppet-master-ca'] {
    value   => 'true',
  }
  Ini_setting['pe_puppet-master-ca_server'] {
    ensure => absent,
  }
  Ini_setting['pe_puppet-master-ca_port'] {
    ensure => absent,
  }

  # Since this is the CA, it may well be created by running `puppet apply`.
  # Make the cert real.
  puppet_certificate { $::clientcert:
    ensure => present,
  }

  #check to see if we 
  if $autosign_servers {
    pe_puppet::ca::autosign { $autosign_servers: }
  }

  # In the event that the agent role is also in effect on this node, it is
  # necessary to install the certificate denoted above BEFORE starting the
  # service. Use collectors to define this conditional dependency.
  Puppet_certificate <| title == $::clientcert     |> ->
  Service            <| title == 'pe-puppet-agent' |>
}
