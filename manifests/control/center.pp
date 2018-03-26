# Class is used to install
#
# @example Installation through class.
#     class {'confluent::control::center':
#       config => {
#         'zookeeper.connect' => {
#           'value' => 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#         },
#         'bootstrap.servers' => {
#           'value' => 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
#         },
#         'confluent.controlcenter.connect.cluster' => {
#           'value' => 'kafka-connect-01.example.com:8083,kafka-connect-02.example.com:8083,kafka-connect-03.example.com:8083'
#         }
#       },
#       environment_settings => {
#         'CONTROL_CENTER_HEAP_OPTS' => {
#           'value' => '-Xmx6g'
#         }
#       }
#     }
#
# @example Hiera based installation
#      include ::confluent::control::center
#
#      confluent::control::center::config:
#        zookeeper.connect:
#          value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#        bootstrap.servers:
#          value: 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
#        confluent.controlcenter.connect.cluster:
#          value: 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083'
#      confluent::control::center::environment_settings:
#        CONTROL_CENTER_HEAP_OPTS:
#          value: -Xmx6g
#
# @param config Hash of configuration values.
# @param environment_settings Hash of environment variables to set for the Kafka scripts.
# @param config_path Location of the server.properties file for the Kafka broker.
# @param environment_file Location of the environment file used to pass environment variables to the Kafka broker.
# @param log_path Location to write the log files to.
# @param user User to run the kafka service as.
# @param service_name Name of the kafka service.
# @param manage_service Flag to determine if the service should be managed by puppet.
# @param service_ensure Ensure setting to pass to service resource.
# @param service_enable Enable setting to pass to service resource.
# @param file_limit File limit to set for the Kafka service (SystemD) only.
class confluent::control::center (
  Variant[String, Array[String]] $bootstrap_servers,
  Variant[String, Array[String]] $zookeeper_connect,
  Variant[String, Array[String]] $connect_cluster = [],
  Integer $control_center_id                      = 1,
  Hash $config                                    = {},
  Hash $environment_settings                      = {},
  Stdlib::Unixpath $data_path                     = $::confluent::params::control_center_data_path,
  Stdlib::Unixpath $config_path                   = $::confluent::params::control_center_config_path,
  Stdlib::Unixpath $logging_config_path           = $::confluent::params::control_center_logging_config_path,
  Stdlib::Unixpath $environment_file              = $::confluent::params::control_center_environment_path,
  Stdlib::Unixpath $log_path                      = $::confluent::params::control_center_log_path,
  String $user                                    = $::confluent::params::control_center_user,
  String $service_name                            = $::confluent::params::control_center_service,
  Boolean $manage_service                         = $::confluent::params::control_center_manage_service,
  Enum['running', 'stopped'] $service_ensure      = $::confluent::params::control_center_service_ensure,
  Boolean $service_enable                         = $::confluent::params::control_center_service_enable,
  Integer $file_limit                             = $::confluent::params::control_center_file_limit,
  Boolean $manage_repository                      = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                      = $::confluent::params::control_center_stop_timeout_secs,
  String $heap_size                               = $::confluent::params::control_center_heap_size,
  Boolean $restart_on_logging_change              = true,
  Boolean $restart_on_change                      = true
) inherits confluent::params {
  include ::confluent

  if($manage_repository) {
    include ::confluent::repository
  }

  $default_environment_settings = {
    'CONTROL_CENTER_HEAP_OPTS' => "-Xmx${heap_size}",
    'CONTROL_CENTER_OPTS'      => '-Djava.net.preferIPv4Stack=true',
    'LOG_DIR'                  => $log_path,
    'KAFKA_LOG4J_OPTS'         => "-Dlog4j.configuration=file:${logging_config_path}"
  }

  confluent::logging { $service_name:
    path => $logging_config_path
  }

  $actual_environment_settings = merge($default_environment_settings, $environment_settings)

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_file,
    config => $actual_environment_settings
  }

  $default_config = {
    'confluent.controlcenter.id'              => $control_center_id,
    'confluent.controlcenter.data.dir'        => $data_path,
    'bootstrap.servers'                       => join(any2array($bootstrap_servers), ','),
    'confluent.controlcenter.connect.cluster' => join(any2array($connect_cluster), ','),
    'zookeeper.connect'                       => join(any2array($zookeeper_connect), ',')
  }

  $actual_config = merge($default_config, $config)
  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }


  user { $user:
    ensure => present
  } ->
  file { [$log_path, $data_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => '__confluent__'
  }

  package { 'confluent-control-center':
    ensure => latest,
    tag    => '__confluent__',
  }

  confluent::systemd::unit { $service_name:
    config => {
      'Service' => {
        'EnvironmentFile' => $environment_file,
        'User'            => $user,
        'ExecStart'       => "/usr/bin/control-center-start ${config_path}",
        'LimitNOFILE'     => $file_limit,
        'TimeoutStopSec'  => $stop_timeout_secs
      }
    }
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
