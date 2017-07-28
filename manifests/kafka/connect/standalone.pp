# Class is used to install
#
# @example Installation through class.
#     class{'confluent::kafka::connect::standalone':
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
#       environment_settings => {
#         'KAFKA_HEAP_OPTS' => {
#           'value' => '-Xmx4000M'
#         }
#       }
#     }
#
# @example Hiera based installation
#     include ::confluent::kafka::connect::standalone
#
#      confluent::kafka::connect::standalone::config:
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
#      confluent::kafka::connect::standalone::connect_settings:environment_settings:
#        KAFKA_HEAP_OPTS:
#          value: '-Xmx4000M'
#
# @param config Settings to pass to the Kafka Connect properties file.
# @param environment_settings Settings to put in the environment file used to pass environment variables to the kafka startup scripts.
# @param config_path Path to the connect properties file.
# @param environment_path The file used to export environment variables that are consumed by Kafka scripts.
# @param log_path The directory to write log files to.
# @param user The user to run Kafka Connect as.
# @param service_name The name of the service to create
# @param manage_service Flag to determine if the service should be enabled.
# @param service_ensure Ensure setting to pass to the service resource.
# @param service_enable Enable setting to pass to the service resource.
# @param file_limit Number of file handles to configure. (SystemD only)
class confluent::kafka::connect::standalone (
  $bootstrap_servers,
  $config               = { },
  $environment_settings = { },
  $connector_configs    = [],
  $config_path          = $::confluent::params::connect_standalone_config_path,
  $environment_path     = $::confluent::params::connect_standalone_environment_path,
  $log_path             = $::confluent::params::connect_standalone_log_path,
  $user                 = $::confluent::params::connect_standalone_user,
  $service_name         = $::confluent::params::connect_standalone_service,
  $manage_service       = $::confluent::params::connect_standalone_manage_service,
  $service_ensure       = $::confluent::params::connect_standalone_service_ensure,
  $service_enable       = $::confluent::params::connect_standalone_service_enable,
  $file_limit           = $::confluent::params::connect_standalone_file_limit,
  $manage_repository    = $::confluent::params::manage_repository,
  $stop_timeout_secs    = $::confluent::params::connect_standalone_stop_timeout_secs,
) inherits ::confluent::params {
  include ::confluent
  include ::confluent::kafka::connect

  if($manage_repository) {
    include ::confluent::repository
  }

  user { $user:
    ensure => present,
    alias  => 'kafka-connect-standalone'
  } ->
  file { $log_path:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true
  }

  $application = 'connect-standalone'


  $java_default_settings = {
    'KAFKA_HEAP_OPTS' => {
      'value' => '-Xmx256M'
    },
    'KAFKA_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'GC_LOG_ENABLED'  => {
      'value' => true
    },
    'LOG_DIR'         => {
      'value' => $log_path
    }
  }

  $connect_default_settings = {
    'bootstrap.servers' => {
      'value' => join(any2array($bootstrap_servers), ',')
    }
  }

  $actual_connect_settings = merge($connect_default_settings, $config)

  $ensure_connect_settings_defaults = {
    'ensure'      => 'present',
    'path'        => $config_path,
    'application' => $application
  }

  ensure_resources('confluent::java_property', $actual_connect_settings, $ensure_connect_settings_defaults)

  $actual_java_settings = merge($java_default_settings, $environment_settings)
  $ensure_java_settings_defaults = {
    'path'        => $environment_path,
    'application' => $application
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => 'Apache Kafka Connect by Confluent', },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_path, },
    "${service_name}/Service/ExecStart"       => {
      'value' => "/usr/bin/connect-standalone ${config_path}",
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
      enable => $service_enable
    }
  }

}