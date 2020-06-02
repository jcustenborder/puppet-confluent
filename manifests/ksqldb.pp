# Class is used to install ksqlDB Server.
#
# @example Installation through class.
#       class {'confluent::ksqldb':
#         config => {
#           'auto.offset.reset' => {
#             'value' => true
#           },
#         },
#         environment_settings => {
#           'KSQL_HEAP_OPTS' => {
#             'value' => '-Xmx1024M'
#           }
#         }
#       }
#
# @example Hiera based installation
#    include ::confluent::ksqldb
#
#    confluent::ksqldb::config:
#      auto.offset.reset:
#        value: 'true'
#    confluent::ksqldb::environment_settings:
#      KSQL_HEAP_OPTS:
#        value: -Xmx1024M
#
# @param config Hash of configuration values.
# @param environment_settings Hash of environment variables to set for the ksqlDB server.
# @param config_path Location of the server.properties file for the ksqlDB server.
# @param environment_file Location of the environment file used to pass environment variables to the ksqlDB server.
# @param log_path Location to write the log files to.
# @param user User to run the kafka service as.
# @param manage_user Flag to determine if the user should be managed by puppet.
# @param package_ensure Ensure to be passed to the package installation
# @param service_name Name of the ksqlDB service.
# @param manage_service Flag to determine if the service should be managed by puppet.
# @param service_ensure Ensure setting to pass to service resource.
# @param service_enable Enable setting to pass to service resource.
# @param file_limit File limit to set for the ksqlDB service (SystemD) only.
class confluent::ksqldb (
  Variant[String, Array[String]] $bootstrap_servers,
  Hash $config                               = {},
  Hash $environment_settings                 = {},
  Stdlib::Unixpath $config_path              = $::confluent::params::ksqldb_config_path,
  Stdlib::Unixpath $logging_config_path      = $::confluent::params::ksqldb_logging_config_path,
  Stdlib::Unixpath $environment_file         = $::confluent::params::ksqldb_environment_path,
  Stdlib::Unixpath $log_path                 = $::confluent::params::ksqldb_log_path,
  String $user                               = $::confluent::params::ksqldb_user,
  Boolean $manage_user                       = $::confluent::params::ksqldb_manage_user,
  String $service_name                       = $::confluent::params::ksqldb_service,
  Boolean $manage_service                    = $::confluent::params::ksqldb_manage_service,
  Enum['running', 'stopped'] $service_ensure = $::confluent::params::ksqldb_service_ensure,
  Boolean $service_enable                    = $::confluent::params::ksqldb_service_enable,
  Integer $file_limit                        = $::confluent::params::ksqldb_file_limit,
  Boolean $manage_repository                 = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                 = $::confluent::params::ksqldb_stop_timeout_secs,
  String $heap_size                          = $::confluent::params::ksqldb_heap_size,
  String $package_ensure                     = 'latest',
  Boolean $restart_on_logging_change         = true,
  Boolean $restart_on_change                 = true
) inherits confluent::params {
  include ::confluent

  if($manage_repository) {
    include ::confluent::repository
  }
  $default_config = {
    'bootstrap.servers'         => join(any2array($bootstrap_servers), ','),
    'listeners'                 => 'http://0.0.0.0:8088',
    'debug'                     => false,
  }

  $actual_config = merge($default_config, $config)
  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config,
  }


  $default_environment_settings = {
    'KSQL_HEAP_OPTS'     => "-Xmx${heap_size}",
    'GC_LOG_ENABLED'    => true,
    'LOG_DIR'           => $log_path,
    'KSQL_LOG4J_OPTS'  => "-Dlog4j.configuration=file:${logging_config_path}",
  }
  $actual_environment_settings = merge($default_environment_settings, $environment_settings)

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_file,
    config => $actual_environment_settings,
  }

  confluent::logging { $service_name:
    path   => $logging_config_path,
    config => {
      'log4j.appender.roller.File' => '${ksql.log.dir}/server.log',
    },
  }

  if($manage_user) {
    user { $user:
      ensure => present,
    }
  }

  file { [$log_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => '__confluent__',
  }

  package { 'confluent-ksql':
    ensure => absent,
  }
  ->package { 'confluent-ksqldb':
    ensure => $package_ensure,
    tag    => '__confluent__',
  }

  ensure_packages('confluent-rest-utils', {'ensure' => $package_ensure, 'tag' => '__confluent__'})

  confluent::systemd::unit { $service_name:
    config => {
      'Unit'    => {
        'Description' => 'ksqlDB Server by Confluent',
      },
      'Service' => {
        'User'            => $user,
        'EnvironmentFile' => $environment_file,
        'ExecStart'       => "/usr/bin/ksql-server-start ${config_path}",
        'ExecStop'        => '/usr/bin/ksql-server-stop',
        'LimitNOFILE'     => $file_limit,
      },
    },
  }

  if($manage_service) {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
      tag    => '__confluent__',
    }
    if($restart_on_change) {
      Package['confluent-ksqldb'] ~> Service[$service_name]
      Package['confluent-rest-utils'] ~> Service[$service_name]
      Confluent::Systemd::Unit[$service_name] ~> Service[$service_name]
      Confluent::Environment[$service_name] ~> Service[$service_name]
      Confluent::Properties[$service_name] ~> Service[$service_name]
      if($restart_on_logging_change) {
        Confluent::Logging[$service_name] ~> Service[$service_name]
      }
    }
  }

}
