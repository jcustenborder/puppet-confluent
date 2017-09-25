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
) inherits confluent::params {
  include ::confluent

  if($manage_repository) {
    include ::confluent::repository
  }
  $schemaregistry_default_settings = {
    'kafkastore.connection.url' => {
      'value' => join(any2array($kafkastore_connection_url), ',')
    }
  }

  $java_default_settings = {
    'SCHEMA_REGISTRY_HEAP_OPTS' => {
      'value' => "-Xmx${heap_size}"
    },
    'SCHEMA_REGISTRY_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'GC_LOG_ENABLED'            => {
      'value' => true
    },
    'LOG_DIR'                   => {
      'value' => $log_path
    },
    'KAFKA_LOG4J_OPTS'          => {
      'value' => "-Dlog4j.configuration=file:${logging_config_path}"
    }
  }

  $actual_schemaregistry_settings = prefix(merge($schemaregistry_default_settings, $config), "${service_name}/")
  $actual_java_settings = prefix(merge($java_default_settings, $environment_settings), "${service_name}/")

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
    tag     => 'confluent'
  }

  package { 'confluent-schema-registry':
    ensure => latest,
    tag    => 'confluent',
  }

  $ensure_schemaregistry_settings_defaults = {
    'ensure' => 'present',
    'path'   => $config_path,
  }

  ensure_resources(
    'confluent::java_property',
    $actual_schemaregistry_settings,
    $ensure_schemaregistry_settings_defaults
  )

  $ensure_java_settings_defaults = {
    'path' => $environment_file,
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => 'Schema Registry by Confluent', },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network-online.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' => "/usr/bin/schema-registry-start ${config_path}", },
    "${service_name}/Service/ExecStop"        => { 'value' => '/usr/bin/schema-registry-stop', },
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