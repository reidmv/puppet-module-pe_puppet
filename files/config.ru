# A "config.ru", for use with every Rack-compatible webserver.
# SSL needs to be handled outside this, though.

$0 = "master"

# If you want debugging, uncomment the following line:
# ARGV << "--debug"

ARGV << "--rack"
ARGV << "--confdir" << "/etc/puppetlabs/puppet"
ARGV << "--vardir"  << "/var/opt/lib/pe-puppet"

require "puppet/application/master"

class Puppet::Application::Master
  unless defined?(setup_original) then
    alias :setup_original :setup
  end

  def setup
    setup_original
  end
end

require 'puppet/util/command_line'
# we're usually running inside a Rack::Builder.new {} block,
# therefore we need to call run *here*.
run Puppet::Util::CommandLine.new.execute
