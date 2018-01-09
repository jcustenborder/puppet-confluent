# Class is used to install and configure Kafka Rest Proxy using Confluent installation packages.
#
# @example Installation through class.
#    class { 'confluent::kafka::rest':
#      rest_id             => '1',
#      schema_registry_url => 'http://localhost:8081',
#      zookeeper_servers   => 'localhost:2181',
#    }
#
# @example Hiera based installation
#     include ::confluent::kafka::rest
#
#     confluent::kafka::rest::rest_id: '1'
#     confluent::kafka::rest::schema_registry_url: 'http://localhost:8081'
#     confluent::kafka::rest::zookeeper_servers: 'localhost:2181'
#
# @param rest_id unique ID of this Rest Proxy instance
# @param config Hash of configuration values.
# @param environment_settings Hash of variables to set for rest proxy environment
# @param schema_registry_url URL of the schema registry
# @param zookeeper_servers single url or list of zookeeper urls
# @param config_path Location of the server.properties file for the Kafka broker.
# @param environment_file Location of the environment file used to pass environment variables to rest proxy service
# @param log_path Location to write the log files to.
# @param user User to run the rest proxy service as.
# @param service_name Name of the rest proxy service.
# @param manage_service Flag to determine if the service should be managed by puppet.
# @param service_ensure Ensure setting to pass to service resource.
# @param service_enable Enable setting to pass to service resource.
# @param file_limit File limit to set for the Kafka service (SystemD) only.
# @param heap_size java option to set the max heap size
# @param manage_repository whether puppet should manage the confluent repository
# @param restart_on_logging_change whether to restart the service due to changed logging configuration
class confluent::kafka::rest (
  String $rest_id,
  Hash[String, Variant[String, Integer, Boolean]] $config = {},
  Hash $environment_settings                              = {},
  Variant[String, Array[String]] $schema_registry_url     = 'http://localhost:8081',
  Variant[String, Array[String]] $zookeeper_servers       = 'localhost:2182',
  Stdlib::Unixpath $config_path                           = $::confluent::params::rest_config_path,
  Stdlib::Unixpath $environment_file                      = $::confluent::params::rest_environment_path,
  Stdlib::Unixpath $log_path                              = $::confluent::params::rest_log_path,
  Stdlib::Unixpath $logging_config_path                   = $::confluent::params::rest_logging_config_path,
  String $user                                            = $::confluent::params::rest_user,
  String $service_name                                    = $::confluent::params::rest_service,
  Boolean $manage_service                                 = $::confluent::params::rest_manage_service,
  Enum['running', 'stopped'] $service_ensure              = $::confluent::params::rest_service_ensure,
  Boolean $service_enable                                 = $::confluent::params::rest_service_enable,
  Integer $file_limit                                     = $::confluent::params::rest_file_limit,
  String $heap_size                                       = $::confluent::params::rest_heap_size,
  Boolean $manage_repository                              = $::confluent::params::manage_repository,
  Boolean $restart_on_logging_change                      = true
) inherits confluent::params {
  include ::confluent

  if($manage_repository) {
    include ::confluent::repository
  }

  package { 'confluent-kafka-rest':
    ensure => present,
    tag    => 'confluent',
  }

  $default_config = {
    'id'                  => $rest_id,
    'schema.registry.url' => join(any2array($schema_registry_url, ",")),
    'zookeeper.connect'   => join(any2array($zookeeper_servers), ","),
  }
  $actual_config = merge($default_config, $config)

  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }

  $default_environment_settings = {
    'KAFKAREST_HEAP_OPTS' => "-Xmx${heap_size}",
    'KAFKAREST_OPTS'      => '-Djava.net.preferIPv4Stack=true',
    'GC_LOG_ENABLED'      => true,
    'LOG_DIR'             => $log_path,
    'KAFKA_LOG4J_OPTS'    => "-Dlog4j.configuration=file:${logging_config_path}"
  }
  $actual_environment_settings = merge($default_environment_settings, $environment_settings)

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_file,
    config => $actual_environment_settings
  }

  confluent::logging { $service_name:
    path   => $logging_config_path,
    config => $logging_config
  }

  user { $user:
    ensure => present
  }
  -> file { $log_path:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => 'confluent'
  }

  confluent::systemd::unit { $service_name:
    config => {
      'Unit'    => {
        'Description' => 'Confluent Kafka Rest'
      },
      'Service' => {
        'User'            => $user,
        'EnvironmentFile' => $environment_file,
        'ExecStart'       => "/usr/bin/kafka-rest-start ${config_path}",
        'ExecStop'        => '/usr/bin/kafka-rest-stop',
        'LimitNOFILE'     => $file_limit,
      }
    }
  }

  if ($manage_service) {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
      tag    => 'confluent'
    }
    Confluent::Systemd::Unit[$service_name] ~> Service[$service_name]
    Confluent::Environment[$service_name] ~> Service[$service_name]
    Confluent::Properties[$service_name] ~> Service[$service_name]
    if($restart_on_logging_change) {
      Confluent::Logging[$service_name] ~> Service[$service_name]
    }
  }
}
