class pe_puppet::agent (
  $master_host = hiera('pe_puppet::agent::master_host', 'puppet'),
  $master_port = hiera('pe_puppet::agent::master_port', '8140'),
  $ca_host     = hiera('pe_puppet::agent::ca_host',     'puppetca'),
  $ca_port     = hiera('pe_puppet::agent::ca_port',     '8140'),
  $certname    = hiera('pe_puppet::agent::certname',    $::clientcert),
  $config_file = hiera('pe_puppet::agent::config_file', '/etc/puppetlabs/puppet/puppet.conf'),
) {
  include pe_puppet

  Ini_setting {
    ensure  => present,
    path    => $config_file,
    section => 'agent',
  }

  ini_setting { 'puppet_agent_pluginsync':
    setting => 'pluginsync',
    value   => 'true',
  }
  ini_setting { 'puppet_agent_server':
    setting => 'server',
    value   => $master_host,
  }
  ini_setting { 'puppet_agent_masterport':
    setting => 'masterport',
    value   => $master_port,
  }
  ini_setting { 'puppet_agent_caserver':
    setting => 'ca_server',
    value   => $ca_host,
  }
  ini_setting { 'puppet_agent_caport':
    setting => 'ca_port',
    value   => $ca_port,
  }
  ini_setting { 'puppet_agent_certname':
    setting => 'certname',
    value   => $certname,
  }

  case $::osfamily {
    'Debian': {
      $puppet_agent_service = 'pe-puppet-agent'
      # Debian needs extra enabling
      file_line { 'enable-puppet-agent':
        ensure => present,
        path   => '/etc/default/pe-puppet-agent',
        match  => 'START=',
        line   => 'START=yes',
        before => Service['pe-puppet-agent'],
      }
    }
    'RedHat': { $puppet_agent_service = 'pe-puppet' }
    default: { fail("unexpected osfamily ${::osfamily}") }
  }

  service { 'pe-puppet-agent':
    name    => $puppet_agent_service,
    ensure  => running,
    enable  => true,
    require => Ini_setting['puppet_agent_certname'],
  }

}
