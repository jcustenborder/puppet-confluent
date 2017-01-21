# Class is used to install and configure Apache Zookeeper using the Confluent installation packages.
#
# @example Installation through class.
#     class{'confluent::zookeeper':
#       zookeeper_settings => {
#         'myid' => {
#           'value' => '1'
#         }
#       },
#       java_settings => {
#         'KAFKA_HEAP_OPTS' => {
#           'value' => '-Xmx4000M'
#         }
#       }
#     }
#
# @example Hiera based installation
#    include ::confluent::zookeeper
#
#    confluent::zookeeper::zookeeper_settings:
#      myid:
#        value: '1'
#      server.1:
#        value: 'zookeeper-01.example.com:2888:3888'
#      server.2:
#        value: 'zookeeper-02.example.com:2888:3888'
#      server.3:
#        value: 'zookeeper-03.example.com:2888:3888'
#    confluent::zookeeper::java_settings:
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
  $zookeeper_id,
  $config               = { },
  $environment_settings = { },
  $config_path          = $::confluent::params::zookeeper_config_path,
  $environment_file     = $::confluent::params::zookeeper_environment_path,
  $data_path            = $::confluent::params::zookeeper_data_path,
  $log_path             = $::confluent::params::zookeeper_log_path,
  $user                 = $::confluent::params::zookeeper_user,
  $service_name         = $::confluent::params::zookeeper_service,
  $manage_service       = $::confluent::params::zookeeper_manage_service,
  $service_ensure       = $::confluent::params::zookeeper_service_ensure,
  $service_enable       = $::confluent::params::zookeeper_service_enable,
  $file_limit           = $::confluent::params::zookeeper_file_limit,
) inherits confluent::params {
  include ::confluent::kafka

  validate_hash($config)
  validate_hash($environment_settings)
  validate_absolute_path($config_path)
  validate_absolute_path($log_path)
  validate_absolute_path($config_path)

  $application_name = 'zookeeper'

  $zookeeper_default_settings = {
    'dataDir'        => {
      'value' => $data_path
    },
    'clientPort'     => {
      'value' => 2181
    },
    'maxClientCnxns' => {
      'value' => 0
    },
    'initLimit'      => {
      'value' => 5
    },
    'syncLimit'      => {
      'value' => 2
    }
  }

  $java_default_settings = {
    'KAFKA_HEAP_OPTS' => {
      'value' => '-Xmx256M'
    },
    'KAFKA_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'GC_LOG_ENABLED'  => {
      'value' => 'true'
    },
    'LOG_DIR'         => {
      'value' => $log_path
    }
  }

  $actual_zookeeper_settings = merge($zookeeper_default_settings, $config)
  $actual_java_settings = merge($java_default_settings, $environment_settings)

  $myid_file = "${data_path}/myid"

  user { $user:
    ensure => present
  } ->
  file { [$data_path, $log_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true
  } ->
  file { $myid_file:
    ensure  => present,
    content => "${zookeeper_id}",
    mode    => '0644',
    group   => $user,
    owner   => $user
  }

  Package['confluent-kafka-2.11'] -> Ini_setting <| tag == 'kafka-setting' |>

  $ensure_zookeeper_settings_defaults = {
    'ensure'      => 'present',
    'path'        => $config_path,
    'application' => $application_name
  }

  ensure_resources('confluent::java_property', $actual_zookeeper_settings, $ensure_zookeeper_settings_defaults)

  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => 'zookeeper'
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    'zookeeper/Unit/Description'        => { 'value' => 'Apache Zookeeper by Confluent', },
    'zookeeper/Unit/Wants'              => { 'value' => 'basic.target', },
    'zookeeper/Unit/After'              => { 'value' => 'basic.target network.target', },
    'zookeeper/Service/User'            => { 'value' => $zookeeper_user, },
    'zookeeper/Service/EnvironmentFile' => { 'value' => $environment_file, },
    'zookeeper/Service/ExecStart'       => { 'value' =>
    "/usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties", },
    'zookeeper/Service/ExecStop'        => { 'value' => "/usr/bin/zookeeper-server-stop", },
    'zookeeper/Service/LimitNOFILE'     => { 'value' => $file_limit, },
    'zookeeper/Service/KillMode'        => { 'value' => 'process', },
    'zookeeper/Service/RestartSec'      => { 'value' => 5, },
    'zookeeper/Service/Type'            => { 'value' => 'simple', },
    'zookeeper/Install/WantedBy'        => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)

  if($manage_service) {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable
    }
  }
}