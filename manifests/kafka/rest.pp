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
class confluent::kafka::rest (
  $bootstrap_servers,
  $id                   = $::hostname,
  $zookeeper_connect    = 'localhost:2181',
  $schema_registry_url  = 'http://localhost:8081/',
  $config               = {},
  $environment_settings = {},
  $config_path          = $::confluent::params::kafka_rest_config_path,
  $environment_file     = $::confluent::params::kafka_rest_environment_path,
  $log_path             = $::confluent::params::kafka_rest_log_path,
  $user                 = $::confluent::params::kafka_rest_user,
  $service_name         = $::confluent::params::kafka_rest_service,
  $manage_service       = $::confluent::params::kafka_rest_manage_service,
  $service_ensure       = $::confluent::params::kafka_rest_service_ensure,
  $service_enable       = $::confluent::params::kafka_rest_service_enable,
  $file_limit           = $::confluent::params::kafka_rest_file_limit,
  $manage_repository    = $::confluent::params::manage_repository,
  $stop_timeout_secs    = $::confluent::params::kafka_rest_stop_timeout_secs,
  $heap_size            = $::confluent::params::kafka_rest_heap_size,
) inherits confluent::params {
  include ::confluent

  validate_hash($config)
  validate_hash($environment_settings)
  validate_absolute_path($config_path)
  validate_absolute_path($environment_file)
  validate_absolute_path($log_path)

  if($manage_repository) {
    include ::confluent::repository
  }

  $application_name = 'kafka-rest'

  $kafka_rest_default_settings = {
    'id'                  => {
      'value' => $id
    },
    'bootstrap.servers'   => {
      'value' => join(any2array($bootstrap_servers), ',')
    },
    'schema.registry.url' => {
      'value' => join(any2array($schema_registry_url), ',')
    },
    'zookeeper.connect'   => {
      'value' => join(any2array($zookeeper_connect), ',')
    },
  }

  $java_default_settings = {
    'KAFKAREST_HEAP_OPTS' => {
      'value' => "-Xmx${heap_size}"
    },
    'KAFKAREST_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'GC_LOG_ENABLED'            => {
      'value' => true
    },
    'LOG_DIR'                   => {
      'value' => $log_path
    }
  }


  $actual_schemaregistry_settings = merge($kafka_rest_default_settings, $config)
  $actual_java_settings = merge($java_default_settings, $environment_settings)

  user { $user:
    ensure => present
  } ->
  file { [$log_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true
  }

  package { 'confluent-kafka-rest':
    ensure => latest,
    tag    => 'confluent',
  }

  $ensure_schemaregistry_settings_defaults = {
    'ensure'      => 'present',
    'path'        => $config_path,
    'application' => $application_name
  }

  ensure_resources('confluent::java_property', $actual_schemaregistry_settings, $ensure_schemaregistry_settings_defaults
  )

  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => $application_name
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => 'Schema Registry by Confluent', },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' => "/usr/bin/kafka-rest-start ${config_path}", },
    "${service_name}/Service/ExecStop"        => { 'value' => '/usr/bin/kafka-rest-stop', },
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