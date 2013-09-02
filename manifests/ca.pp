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

  # TODO: Make this more extensible. This implementation rings of hard-coding.
  #       what is needed is a type/providere for auth_conf entries, that is NOT
  #       concat-based.
  include auth_conf
  include auth_conf::defaults
  auth_conf::acl { '/certificate_status for multiple dashboards':
    path       => '/certificate_status',
    auth       => 'yes',
    acl_method => [ 'find', 'search', 'save', 'destroy' ],
    allow      => '/^pe-internal-dashboard\.?.*$/',
    order      => 084,
  }
  auth_conf::acl { '/facts for multiple masters':
    path       => '/facts',
    auth       => 'yes',
    acl_method => ['save'],
    allow      => '/^pe-internal-puppetmaster\.?.*$/',
    order      => 094,
  }

}
