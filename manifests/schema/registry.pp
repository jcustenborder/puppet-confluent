# Class is used to install
#
# @example Installation through class.
#       class {'confluent::schema::registry':
#         schemaregistry_settings => {
#           'kafkastore.connection.url' => {
#             'value' => 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#           },
#         },
#         java_settings => {
#           'SCHEMA_REGISTRY_HEAP_OPTS' => {
#             'value' => '-Xmx1024M'
#           }
#         }
#       }
#
# @example Hiera based installation
#    include ::confluent::schema::registry
#
#    confluent::schema::registry::schemaregistry_settings:
#      kafkastore.connection.url:
#        value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#    confluent::schema::registry::java_settings:
#      SCHEMA_REGISTRY_HEAP_OPTS:
#        value: -Xmx1024M
#
# @param schemaregistry_user System user to run the schema registry service as.
# @param schemaregistry_settings Settings to put in the environment file used to pass environment variables to the kafka startup scripts.
# @param java_settings Path to the connect properties file.
class confluent::schema::registry (
  $schemaregistry_user = 'schemaregistry',
  $schemaregistry_settings = { },
  $java_settings = { }
) {
  validate_hash($schemaregistry_settings)
  validate_hash($java_settings)

  $schemaregistry_default_settings = {

  }

  $java_default_settings = {
    'SCHEMA_REGISTRY_HEAP_OPTS' => {
      'value' => '-Xmx512M'
    },
    'SCHEMA_REGISTRY_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'GC_LOG_ENABLED'  => {
      'value' => 'true'
    },
    'LOG_DIR'         => {
      'value' => '/var/log/schema-registry'
    }
  }


  $actual_schemaregistry_settings = merge($schemaregistry_default_settings, $schemaregistry_settings)
  $actual_java_settings = merge($java_default_settings, $java_settings)

  $log4j_log_dir = $actual_java_settings['LOG_DIR']['value']
  validate_absolute_path($log4j_log_dir)

  user{ $schemaregistry_user:
    ensure => present
  } ->
  file{ [$log4j_log_dir]:
    ensure  => directory,
    owner   => $schemaregistry_user,
    group   => $schemaregistry_user,
    recurse => true
  }

  package{ 'confluent-schema-registry':
    alias  => 'schema-registry',
    ensure => latest
  } -> Ini_setting <| tag == 'kafka-setting' |> -> Ini_subsetting <| tag == 'schemaregistry-setting' |>

  $ensure_schemaregistry_settings_defaults={
    'ensure' => 'present',
    'path'   => '/etc/schema-registry/schema-registry.properties',
    'application' => 'schema-registry'
  }

  ensure_resources('confluent::java_property', $actual_schemaregistry_settings, $ensure_schemaregistry_settings_defaults)

  $environment_file='/etc/sysconfig/schema-registry'

  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => 'schemaregistry'
  }

  ensure_resources('confluent::java_setting', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    'schema-registry/Unit/Description'               => { 'value' => 'Schema Registry by Confluent', },
    'schema-registry/Unit/Wants'                     => { 'value' => 'basic.target', },
    'schema-registry/Unit/After'                     => { 'value' => 'basic.target network.target', },
    'schema-registry/Service/User'                   => { 'value' => $schemaregistry_user, },
    'schema-registry/Service/EnvironmentFile'        => { 'value' => $environment_file, },
    'schema-registry/Service/ExecStart'              => { 'value' => "/usr/bin/schema-registry-start /etc/schema-registry/schema-registry.properties", },
    'schema-registry/Service/ExecStop'               => { 'value' => "/usr/bin/schema-registry-stop", },
    'schema-registry/Service/LimitNOFILE'            => { 'value' => 131072, },
    'schema-registry/Service/KillMode'               => { 'value' => 'process', },
    'schema-registry/Service/RestartSec'             => { 'value' => 5, },
    'schema-registry/Service/Type'                   => { 'value' => 'simple', },
    'schema-registry/Install/WantedBy'               => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)
}