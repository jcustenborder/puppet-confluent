# Class is used to install and configure Apache Zookeeper using the Confluent installation packages.
#
# @example Installation through class.
#     class{'confluent::zookeeper':
#       zookeeper_id => '1',
#       environment_settings => {
#         'KAFKA_HEAP_OPTS' => {
#           'value' => '-Xmx4000M'
#         }
#       }
#     }
#
# @example Hiera based installation
#    include ::confluent::zookeeper
#
#    confluent::zookeeper::zookeeper_id: '1'
#    confluent::zookeeper::config:
#      server.1:
#        value: 'zookeeper-01.example.com:2888:3888'
#      server.2:
#        value: 'zookeeper-02.example.com:2888:3888'
#      server.3:
#        value: 'zookeeper-03.example.com:2888:3888'
#    confluent::zookeeper::environment_settings:
#      KAFKA_HEAP_OPTS:
#        value: '-Xmx4000M'
#
# @param zookeeper_id ID of the current zookeeper node.
# @param config Hash of configuration values.
# @param environment_settings Hash of environment variables to set for the Kafka scripts.
# @param config_path Location of the server.properties file for the Kafka broker.
# @param environment_file Location of the environment file used to pass environment variables to the Kafka broker.
# @param data_path Location to store the data on disk.
# @param log_path Location to write the log files to.
# @param user User to run the kafka service as.
# @param service_name Name of the kafka service.
# @param manage_service Flag to determine if the service should be managed by puppet.
# @param service_ensure Ensure setting to pass to service resource.
# @param service_enable Enable setting to pass to service resource.
# @param file_limit File limit to set for the Kafka service (SystemD) only.
class confluent::zookeeper (
  Integer $zookeeper_id,
  Hash $config                               = {},
  Hash $environment_settings                 = {},
  Stdlib::Unixpath $config_path              = $::confluent::params::zookeeper_config_path,
  Stdlib::Unixpath $logging_config_path      = $::confluent::params::zookeeper_logging_config_path,
  Stdlib::Unixpath $environment_path         = $::confluent::params::zookeeper_environment_path,
  Stdlib::Unixpath $data_path                = $::confluent::params::zookeeper_data_path,
  Stdlib::Unixpath $log_path                 = $::confluent::params::zookeeper_log_path,
  String $user                               = $::confluent::params::zookeeper_user,
  String $service_name                       = $::confluent::params::zookeeper_service,
  Boolean $manage_service                    = $::confluent::params::zookeeper_manage_service,
  Enum['running', 'stopped'] $service_ensure = $::confluent::params::zookeeper_service_ensure,
  Boolean $service_enable                    = $::confluent::params::zookeeper_service_enable,
  Integer $file_limit                        = $::confluent::params::zookeeper_file_limit,
  Boolean $manage_repository                 = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                 = $::confluent::params::zookeeper_stop_timeout_secs,
  String $heap_size                          = $::confluent::params::zookeeper_heap_size,
  Boolean $restart_on_logging_change         = true,
  Boolean $restart_on_change                 = true
) inherits confluent::params {
  include ::confluent::kafka

  if($manage_repository) {
    include ::confluent::repository
  }

  $default_config = {
    'dataDir'                   => $data_path,
    'clientPort'                => 2181,
    'maxClientCnxns'            => 0,
    'initLimit'                 => 5,
    'syncLimit'                 => 2,
    'autopurge.snapRetainCount' => 10,
    'autopurge.purgeInterval'   => 1,
  }
  $actual_config = merge($default_config, $config)

  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }

  $default_environment_settings = {
    'KAFKA_HEAP_OPTS'  => "-Xmx${heap_size}",
    'KAFKA_OPTS'       => '-Djava.net.preferIPv4Stack=true',
    'GC_LOG_ENABLED'   => true,
    'LOG_DIR'          => $log_path,
    'KAFKA_LOG4J_OPTS' => "-Dlog4j.configuration=file:${logging_config_path}"
  }
  $actual_environment_settings = merge($default_environment_settings, $environment_settings)

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_path,
    config => $actual_environment_settings
  }

  confluent::logging { $service_name:
    path => $logging_config_path
  }

  $myid_file = "${data_path}/myid"

  user { $user:
    ensure => present
  } ->
  file { [$data_path, $log_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    recurselimit => 1,
    tag     => '__confluent__'
  } ->
  file { $myid_file:
    ensure  => present,
    content => inline_template("<%=@zookeeper_id%>"),
    mode    => '0644',
    group   => $user,
    owner   => $user,
    tag     => '__confluent__'
  }

  confluent::systemd::unit { $service_name:
    config => {
      'Unit'    => {
        'Description' => 'Apache Zookeeper by Confluent'
      },
      'Service' => {
        'User'            => $user,
        'EnvironmentFile' => $environment_path,
        'ExecStart'       => "/usr/bin/zookeeper-server-start ${config_path}",
        'ExecStop'        => '/usr/bin/zookeeper-server-stop',
        'LimitNOFILE'     => $file_limit,
      }
    },
  }

  if($manage_service) {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
      tag    => '__confluent__'
    }
    if($restart_on_change) {
      Confluent::Systemd::Unit[$service_name] ~> Service[$service_name]
      Confluent::Environment[$service_name] ~> Service[$service_name]
      Confluent::Properties[$service_name] ~> Service[$service_name]
      if($restart_on_logging_change) {
        Confluent::Logging[$service_name] ~> Service[$service_name]
      }
    }
  }
}
