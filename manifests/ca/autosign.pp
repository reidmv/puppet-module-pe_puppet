define pe_puppet::ca::autosign ( ) {
  file_line { $title:
    ensure => present,
    path   => '/etc/puppet/autosign.conf',
    line   => "${name}",
  }
}
