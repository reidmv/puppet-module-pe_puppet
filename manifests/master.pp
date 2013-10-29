## Add inventory service params...
## Add storedconfig params (not enabled by default, but is configurable) [bonus points]
class pe_puppet::master (
  $ca_host               = undef,
  $ca_port               = '8140',
  $console_host          = undef,
  $console_port          = '443',
  $puppetdb_host         = undef,
  $puppetdb_port         = '8081',
  $config_file           = '/etc/puppetlabs/puppet/puppet.conf',
  $certname              = "pe-internal-puppetmaster.${::clientcert}",
  $dns_alt_names         = "${::hostname},puppet,puppet.${::domain}",
  $confdir               = '/etc/puppetlabs/puppet',
  $inventory_dbname      = 'console_inventory_service',
  $inventory_dbuser      = 'console',
  $inventory_dbpassword  = undef,
  $inventory_dbhost      = undef,
  $reports               = 'https',
  $external_nodes        = '/etc/puppetlabs/puppet-dashboard/external_node',
  $modulepath            = '/etc/puppetlabs/puppet/modules:/opt/puppet/share/puppet/modules',
  $manifest              = undef,
  $waitforcert           = '120',
  $puppet_server_version = installed,
) {
  include pe_puppet
  include pe_httpd

  File {
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    mode    => '0640',
    require => Package['pe-puppet-master'],
  }

  Ini_setting {
    ensure  => present,
    path    => "${confdir}/puppet.conf",
    section => 'master',
  }

  package { 'pe-puppet-server':
    ensure => $puppet_server_version,
  }

  # In order to allow agents to be "graduated" to masters, an alternate
  # certificate is used for the master. The dns_alt_names is what makes
  # it complicated and easier just to use a new cert.
  puppet_certificate { $certname:
    ensure        => present,
    dns_alt_names => $dns_alt_names,
    waitforcert   => $waitforcert,
  }
  ini_setting { 'pe_puppet-master-certname':
    setting => 'certname',
    value   => $certname,
  }

  ini_setting { 'pe_puppet-master-ssl_client_header':
    setting => 'ssl_client_header',
    value   => 'SSL_CLIENT_S_DN',
  }
  ini_setting { 'pe_puppet-master-ssl_client_verify_header':
    setting => 'ssl_client_verify_header',
    value   => 'SSL_CLIENT_VERIFY',
  }
  if $modulepath {
    ini_setting { 'pe_puppet-master-modulepath':
      setting => 'modulepath',
      value   => $modulepath,
    }
  }

  # Template uses:
  # - $certname
  pe_httpd::vhost { 'puppetmaster':
    content => template('pe_puppet/puppetmaster.conf.erb'),
    require => [
      Puppet_certificate[$certname],
      Package['pe-puppet-server'],
    ],
  }
  file { '/var/opt/lib/pe-puppetmaster':
    ensure => directory,
    mode   => '0750',
  }
  file { '/var/opt/lib/pe-puppetmaster/config.ru':
    ensure => file,
    source => 'puppet:///modules/pe_puppet/config.ru',
    notify => Service['pe-httpd'],
  }
  file { '/var/opt/lib/pe-puppetmaster/public':
    ensure => directory,
    mode   => '0755',
    notify => Service['pe-httpd'],
  }
  file { '/var/opt/lib/pe-puppet/reports':
    ensure => directory,
    mode   => '0750',
  }

  # Serve up the contents of this Puppet Master's hiera.yaml
  file { "${confdir}/hiera.yaml":
    content => file("${::settings::confdir}/hiera.yaml", '/dev/null'),
  }

  # CA configuration
  ini_setting { 'pe_puppet-master-ca':
    setting => 'ca',
    value   => 'false',
  }
  ini_setting { 'pe_puppet-master-ca_server':
    setting => 'ca_server',
    value   => $ca_host,
  }
  ini_setting { 'pe_puppet-master-ca_port':
    setting => 'ca_port',
    value   => $ca_port,
  }

  # Console configuration
  if $console_host {
    file { '/etc/puppetlabs/puppet-dashboard/external_node':
      content => template('pe_puppet/external_node.erb'),
      mode    => '0755',
    }
    ini_setting { 'pe_puppet-master-reporturl':
      setting => 'reporturl',
      value   => "https://${console_host}:${console_port}/reports/upload",
    }
    ini_setting { 'pe_puppet-master-node_terminus':
      setting => 'node_terminus',
      value   => 'exec',
    }
    ini_setting { 'pe_puppet-master-external_nodes':
      setting => 'external_nodes',
      value   => $external_nodes,
    }
  }
  if $reports {
    ini_setting { 'pe_puppet-master-reports':
      setting => 'reports',
      value   => $reports,
    }
  }

  if $manifest {
    ini_setting { 'pe_puppet-master-manifest':
      setting => 'manifest',
      value   => $manifest,
    }
  }

  # inventory_active_record facts terminus settings
  if (!$puppetdb_host or ($puppetdb_host == '')) {
    ini_setting { 'pe_puppet-master-facts_terminus':
      setting => 'facts_terminus',
      value   => 'inventory_active_record',
    }
    ini_setting { 'pe_puppet-master-dbadapter':
      setting => 'dbadapter',
      value   => 'mysql',
    }
    ini_setting { 'pe_puppet-master-dbname':
      setting => 'dbname',
      value   => $inventory_dbname,
    }
    ini_setting { 'pe_puppet-master-dbuser':
      setting => 'dbuser',
      value   => $inventory_dbuser,
    }
    if $inventory_dbpassword {
      ini_setting { 'pe_puppet-master-dbpassword':
        setting => 'dbpassword',
        value   => $inventory_dbpassword,
      }
    }
    if $inventory_dbhost {
      ini_setting { 'pe_puppet-master-dbserver':
        setting => 'dbserver',
        value   => $inventory_dbhost,
      }
    }
  }

}
