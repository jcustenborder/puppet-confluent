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
  Stdlib::Absolutepath $config_path          = $::confluent::params::zookeeper_config_path,
  Stdlib::Absolutepath $environment_file     = $::confluent::params::zookeeper_environment_path,
  Stdlib::Absolutepath $data_path            = $::confluent::params::zookeeper_data_path,
  Stdlib::Absolutepath $log_path             = $::confluent::params::zookeeper_log_path,
  String $user                               = $::confluent::params::zookeeper_user,
  String $service_name                       = $::confluent::params::zookeeper_service,
  Boolean $manage_service                    = $::confluent::params::zookeeper_manage_service,
  Enum['running', 'stopped'] $service_ensure = $::confluent::params::zookeeper_service_ensure,
  Boolean $service_enable                    = $::confluent::params::zookeeper_service_enable,
  Integer $file_limit                        = $::confluent::params::zookeeper_file_limit,
  Boolean $manage_repository                 = $::confluent::params::manage_repository,
  Integer $stop_timeout_secs                 = $::confluent::params::zookeeper_stop_timeout_secs,
  String $heap_size                          = $::confluent::params::zookeeper_heap_size,
) inherits confluent::params {
  include ::confluent::kafka

  if($manage_repository) {
    include ::confluent::repository
  }

  validate_hash($config)
  validate_hash($environment_settings)
  validate_absolute_path($config_path)
  validate_absolute_path($log_path)
  validate_absolute_path($config_path)

  $application = 'zookeeper'

  $zookeeper_default_settings = {
    'dataDir'                   => {
      'value' => $data_path
    },
    'clientPort'                => {
      'value' => 2181
    },
    'maxClientCnxns'            => {
      'value' => 0
    },
    'initLimit'                 => {
      'value' => 5
    },
    'syncLimit'                 => {
      'value' => 2
    },
    'autopurge.snapRetainCount' => {
      'value' => 10
    },
    'autopurge.purgeInterval'   => {
      'value' => 1
    },
  }

  $java_default_settings = {
    'KAFKA_HEAP_OPTS' => {
      'value' => "-Xmx${heap_size}"
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

  $actual_zookeeper_settings = prefix(merge($zookeeper_default_settings, $config), "${application}/")
  $actual_java_settings = prefix(merge($java_default_settings, $environment_settings), "${application}/")

  $myid_file = "${data_path}/myid"

  user { $user:
    ensure => present
  } ->
  file { [$data_path, $log_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => 'confluent'
  } ->
  file { $myid_file:
    ensure  => present,
    content => $zookeeper_id,
    mode    => '0644',
    group   => $user,
    owner   => $user,
    tag     => 'confluent'
  }

  $ensure_zookeeper_settings_defaults = {
    'ensure' => 'present',
    'path'   => $config_path,
  }

  ensure_resources(
    'confluent::java_property',
    $actual_zookeeper_settings,
    $ensure_zookeeper_settings_defaults
  )

  $ensure_java_settings_defaults = {
    'path' => $environment_file,
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => 'Apache Zookeeper by Confluent', },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network-online.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' =>
    "/usr/bin/zookeeper-server-start ${config_path}", },
    "${service_name}/Service/ExecStop"        => { 'value' => '/usr/bin/zookeeper-server-stop', },
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