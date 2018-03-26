# Class is used to install
#
# @example Installation through class.
#     class{'confluent::kafka::connect::distributed':
#       config => {
#         'bootstrap.servers' => {
#           'value' => 'broker-01:9092,broker-02:9092,broker-03:9092'
#         },
#         'key.converter' => {
#           'value' => 'io.confluent.connect.avro.AvroConverter'
#         },
#         'value.converter' => {
#           'value' => 'io.confluent.connect.avro.AvroConverter'
#         },
#         'key.converter.schema.registry.url' => {
#           'value' => 'http://schema-registry-01:8081'
#         },
#         'value.converter.schema.registry.url' => {
#           'value' => 'http://schema-registry-01:8081'
#         },
#       },
#       java_settings => {
#         'KAFKA_HEAP_OPTS' => {
#           'value' => '-Xmx4000M'
#         }
#       }
#     }
#
# @example Hiera based installation
#     include ::confluent::kafka::connect::distributed
#
#      confluent::kafka::connect::distributed::config:
#        'bootstrap.servers':
#          value: 'broker-01:9092,broker-02:9092,broker-03:9092'
#        'key.converter':
#          value: 'io.confluent.connect.avro.AvroConverter'
#        'value.converter':
#          value: 'io.confluent.connect.avro.AvroConverter'
#        'key.converter.schema.registry.url':
#          value: 'http://schema-registry-01.example.com:8081'
#        'value.converter.schema.registry.url':
#          value: 'http://schema-registry-01.example.com:8081'
#      confluent::kafka::connect::distributed::connect_settings:java_settings:
#        KAFKA_HEAP_OPTS:
#          value: '-Xmx4000M'
#
# @param config Settings to pass to the Kafka Connect properties file.
# @param environment_settings Settings to put in the environment file used to pass environment variables to the kafka startup scripts.
# @param config_path Path to the connect properties file.
# @param environment_file The file used to export environment variables that are consumed by Kafka scripts.
# @param log_path The directory to write log files to.
# @param user The user to run Kafka Connect as.
# @param service_name The name of the service to create
# @param manage_service Flag to determine if the service should be enabled.
# @param service_ensure Ensure setting to pass to the service resource.
# @param service_enable Enable setting to pass to the service resource.
# @param file_limit Number of file handles to configure. (SystemD only)
class confluent::kafka::connect::distributed (
  Variant[String, Array[String]] $bootstrap_servers,
  Hash $config                                         = {},
  Hash $environment_settings                           = {},
  Stdlib::Unixpath $config_path                        = $::confluent::params::connect_distributed_config_path,
  Stdlib::Unixpath $logging_config_path                = $::confluent::params::connect_distributed_logging_config_path,
  Stdlib::Unixpath $environment_path                   = $::confluent::params::connect_distributed_environment_path,
  Stdlib::Unixpath $log_path                           = $::confluent::params::connect_distributed_log_path,
  String $user                                         = $::confluent::params::connect_distributed_user,
  String $service_name                                 = $::confluent::params::connect_distributed_service,
  Boolean $manage_service                              = $::confluent::params::connect_distributed_manage_service,
  Enum['running', 'stopped'] $service_ensure           = $::confluent::params::connect_distributed_service_ensure,
  Boolean $service_enable                              = $::confluent::params::connect_distributed_service_enable,
  Integer $file_limit                                  = $::confluent::params::connect_distributed_file_limit,
  Boolean $manage_repository                           = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                           = $::confluent::params::connect_distributed_stop_timeout_secs,
  String $heap_size                                    = $::confluent::params::connect_distributed_heap_size,
  Boolean $restart_on_logging_change                   = $::confluent::params::connect_distributed_restart_on_logging_change,
  Boolean $restart_on_change                           = $::confluent::params::connect_distributed_restart_on_change,
  Integer $config_storage_topic_replication_factor     = $::confluent::params::connect_distributed_config_storage_topic_replication_factor,
  String $config_storage_topic_name                    = $::confluent::params::connect_distributed_config_storage_topic_name,
  Integer $offset_storage_topic_replication_factor     = $::confluent::params::connect_distributed_offset_storage_topic_replication_factor,
  String $offset_storage_topic_name                    = $::confluent::params::connect_distributed_offset_storage_topic_name,
  Integer $status_storage_topic_replication_factor     = $::confluent::params::connect_distributed_status_storage_topic_replication_factor,
  String $status_storage_topic_name                    = $::confluent::params::connect_distributed_status_storage_topic_name,
  String $group_id                                     = $::confluent::params::connect_distributed_group_id,
  Array[Stdlib::Unixpath] $plugin_path                 = $::confluent::params::connect_distributed_plugin_path,
  String $key_converter                                = $::confluent::params::connect_distributed_key_converter,
  String $value_converter                              = $::confluent::params::connect_distributed_value_converter,
  Variant[String, Array[String]] $schema_registry_urls = ['http://localhost:8081/']
) inherits ::confluent::params {
  include ::confluent
  include ::confluent::kafka::connect

  if($manage_repository) {
    include ::confluent::repository
  }

  user { $user:
    ensure => present,
    alias  => 'kafka-connect-distributed'
  } ->
  file { $log_path:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => '__confluent__'
  }

  confluent::logging { $service_name:
    path => $logging_config_path
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

  if($key_converter == 'io.confluent.connect.avro.AvroConverter' and
    !has_key($config, 'key.converter.schema.registry.url')) {
    fail('key.converter.schema.registry.url must be defined in $config' )
  }

  if($value_converter == 'io.confluent.connect.avro.AvroConverter' and
    !has_key($config, 'value.converter.schema.registry.url')) {
      fail('value.converter.schema.registry.url must be defined in $config' )
  }

  $default_config = {
    'bootstrap.servers'                       => join(any2array($bootstrap_servers), ','),
    'config.storage.replication.factor'       => $config_storage_topic_replication_factor,
    'config.storage.topic'                    => $config_storage_topic_name,
    'status.storage.replication.factor'       => $status_storage_topic_replication_factor,
    'status.storage.topic'                    => $status_storage_topic_name,
    'offset.storage.replication.factor'       => $offset_storage_topic_replication_factor,
    'offset.storage.topic'                    => $offset_storage_topic_name,
    'internal.key.converter.schemas.enable '  => false,
    'internal.key.converter'                  => 'org.apache.kafka.connect.json.JsonConverter',
    'internal.value.converter.schemas.enable' => false,
    'internal.value.converter'                => 'org.apache.kafka.connect.json.JsonConverter',
    'plugin.path'                             => join($plugin_path, ','),
    'group.id'                                => $group_id,
    'key.converter'                           => $key_converter,
    'key.converter.schema.registry.url'     => join(any2array($schema_registry_urls), ','),
    'key.converter.schemas.enable'            => false,
    'value.converter'                         => $value_converter,
    'value.converter.schema.registry.url'     => join(any2array($schema_registry_urls), ','),
    'value.converter.schemas.enable'          => false
  }
  $actual_config = merge($default_config, $config)
  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }

  confluent::systemd::unit { $service_name:
    config => {
      'Unit'    => {
        'Description' => 'Apache Kafka Connect by Confluent'
      },
      'Service' => {
        'User'            => $user,
        'EnvironmentFile' => $environment_path,
        'ExecStart'       => "/usr/bin/connect-distributed ${config_path}",
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
