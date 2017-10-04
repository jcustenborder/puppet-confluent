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
  Hash $config                               = {},
  Hash $environment_settings                 = {},
  Stdlib::Unixpath $config_path              = $::confluent::params::connect_distributed_config_path,
  Stdlib::Unixpath $logging_config_path      = $::confluent::params::connect_distributed_logging_config_path,
  Stdlib::Unixpath $environment_path         = $::confluent::params::connect_distributed_environment_path,
  Stdlib::Unixpath $log_path                 = $::confluent::params::connect_distributed_log_path,
  String $user                               = $::confluent::params::connect_distributed_user,
  String $service_name                       = $::confluent::params::connect_distributed_service,
  Boolean $manage_service                    = $::confluent::params::connect_distributed_manage_service,
  Enum['running', 'stopped'] $service_ensure = $::confluent::params::connect_distributed_service_ensure,
  Boolean $service_enable                    = $::confluent::params::connect_distributed_service_enable,
  Integer $file_limit                        = $::confluent::params::connect_distributed_file_limit,
  Boolean $manage_repository                 = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                 = $::confluent::params::connect_distributed_stop_timeout_secs,
  String $heap_size                          = $::confluent::params::connect_distributed_heap_size
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
    tag     => 'confluent'
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

  $default_config = {
    'bootstrap.servers' => join(any2array($bootstrap_servers), ',')
  }
  $actual_config = merge($default_config, $config)
  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }



  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => 'Apache Kafka Connect by Confluent', },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network-online.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_path, },
    "${service_name}/Service/ExecStart"       => {
      'value' => "/usr/bin/connect-distributed ${config_path}",
    },
    "${service_name}/Service/LimitNOFILE"     => { 'value' => $file_limit, },
    "${service_name}/Service/KillMode"        => { 'value' => 'process', },
    "${service_name}/Service/RestartSec"      => { 'value' => 5, },
    "${service_name}/Service/TimeoutStopSec"  => { 'value' => $stop_timeout_secs, },
    "${service_name}/Service/Type"            => { 'value' => 'simple', },
    "${service_name}/Install/WantedBy"        => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)

  if($manage_service) {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
      tag    => 'confluent'
    }
    Ini_setting<| tag == "confluent-${service_name}" |> ~> Service[$service_name]
    Ini_subsetting<| tag == "confluent-${service_name}" |> ~> Service[$service_name]
  }

}