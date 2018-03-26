# Class is used to install
#
# @example Installation through class.
#       class {'confluent::schema::registry':
#         config => {
#           'kafkastore.connection.url' => {
#             'value' => 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#           },
#         },
#         environment_settings => {
#           'SCHEMA_REGISTRY_HEAP_OPTS' => {
#             'value' => '-Xmx1024M'
#           }
#         }
#       }
#
# @example Hiera based installation
#    include ::confluent::schema::registry
#
#    confluent::schema::registry::config:
#      kafkastore.connection.url:
#        value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#    confluent::schema::registry::environment_settings:
#      SCHEMA_REGISTRY_HEAP_OPTS:
#        value: -Xmx1024M
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
class confluent::schema::registry (
  Variant[String, Array[String]] $kafkastore_connection_url,
  Hash $config                               = {},
  Hash $environment_settings                 = {},
  Stdlib::Unixpath $config_path              = $::confluent::params::schema_registry_config_path,
  Stdlib::Unixpath $logging_config_path      = $::confluent::params::schema_registry_logging_config_path,
  Stdlib::Unixpath $environment_file         = $::confluent::params::schema_registry_environment_path,
  Stdlib::Unixpath $log_path                 = $::confluent::params::schema_registry_log_path,
  String $user                               = $::confluent::params::schema_registry_user,
  String $service_name                       = $::confluent::params::schema_registry_service,
  Boolean $manage_service                    = $::confluent::params::schema_registry_manage_service,
  Enum['running', 'stopped'] $service_ensure = $::confluent::params::schema_registry_service_ensure,
  Boolean $service_enable                    = $::confluent::params::schema_registry_service_enable,
  Integer $file_limit                        = $::confluent::params::schema_registry_file_limit,
  Boolean $manage_repository                 = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                 = $::confluent::params::schema_registry_stop_timeout_secs,
  String $heap_size                          = $::confluent::params::schema_registry_heap_size,
  Boolean $restart_on_logging_change         = true,
  Boolean $restart_on_change                 = true
) inherits confluent::params {
  include ::confluent

  if($manage_repository) {
    include ::confluent::repository
  }
  $default_config = {
    'kafkastore.connection.url' => join(any2array($kafkastore_connection_url), ','),
    'listeners'                 => 'http://0.0.0.0:8081',
    'kafkastore.topic'          => '_schemas',
    'debug'                     => false
  }

  $actual_config = merge($default_config, $config)
  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }


  $default_environment_settings = {
    'SCHEMA_REGISTRY_HEAP_OPTS' => "-Xmx${heap_size}",
    'SCHEMA_REGISTRY_OPTS'      => '-Djava.net.preferIPv4Stack=true',
    'GC_LOG_ENABLED'            => true,
    'LOG_DIR'                   => $log_path,
    'KAFKA_LOG4J_OPTS'          => "-Dlog4j.configuration=file:${logging_config_path}"
  }
  $actual_environment_settings = merge($default_environment_settings, $environment_settings)

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_file,
    config => $actual_environment_settings
  }

  confluent::logging { $service_name:
    path => $logging_config_path
  }

  user { $user:
    ensure => present
  } ->
  file { [$log_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => '__confluent__'
  }

  package { 'confluent-schema-registry':
    ensure => latest,
    tag    => '__confluent__',
  }

  confluent::systemd::unit { $service_name:
    config => {
      'Unit'    => {
        'Description' => 'Schema Registry by Confluent'
      },
      'Service' => {
        'User'            => $user,
        'EnvironmentFile' => $environment_file,
        'ExecStart'       => "/usr/bin/schema-registry-start ${config_path}",
        'ExecStop'        => '/usr/bin/schema-registry-stop',
        'LimitNOFILE'     => $file_limit,
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
