class pe_puppet (
  $config_file    = '/etc/puppetlabs/puppet/puppet.conf',
  $puppet_version = installed,
  $ca_location    = undef,
) {

  Ini_setting {
    ensure  => present,
    path    => $config_file,
    section => 'main',
  }

  package { 'pe-puppet':
    ensure => $puppet_version,
  }

  # General settings
  ini_setting { 'pe_puppet-ssldir':
    setting => 'ssldir',
    value   => '/etc/puppetlabs/puppet/ssl',
  }
  ini_setting { 'pe_puppet-user':
    setting => 'user',
    value   => 'pe-puppet',
  }
  ini_setting { 'pe_puppet-group':
    setting => 'group',
    value   => 'pe-puppet',
  }

  file { $config_file:
    ensure => file,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '640',
  }

}
