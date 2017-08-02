# Class is used to install
#
# @example Installation through class.
#     class {'confluent::control::center':
#       config => {
#         'zookeeper.connect' => {
#           'value' => 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#         },
#         'bootstrap.servers' => {
#           'value' => 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
#         },
#         'confluent.controlcenter.connect.cluster' => {
#           'value' => 'kafka-connect-01.example.com:8083,kafka-connect-02.example.com:8083,kafka-connect-03.example.com:8083'
#         }
#       },
#       environment_settings => {
#         'CONTROL_CENTER_HEAP_OPTS' => {
#           'value' => '-Xmx6g'
#         }
#       }
#     }
#
# @example Hiera based installation
#      include ::confluent::control::center
#
#      confluent::control::center::config:
#        zookeeper.connect:
#          value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#        bootstrap.servers:
#          value: 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
#        confluent.controlcenter.connect.cluster:
#          value: 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083'
#      confluent::control::center::environment_settings:
#        CONTROL_CENTER_HEAP_OPTS:
#          value: -Xmx6g
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
class confluent::control::center (
  $bootstrap_servers,
  $zookeeper_connect,
  $connect_cluster      = [],
  $control_center_id    = 1,
  $config               = {},
  $environment_settings = {},
  $data_path            = $::confluent::params::control_center_data_path,
  $config_path          = $::confluent::params::control_center_config_path,
  $environment_file     = $::confluent::params::control_center_environment_path,
  $log_path             = $::confluent::params::control_center_log_path,
  $user                 = $::confluent::params::control_center_user,
  $service_name         = $::confluent::params::control_center_service,
  $manage_service       = $::confluent::params::control_center_manage_service,
  $service_ensure       = $::confluent::params::control_center_service_ensure,
  $service_enable       = $::confluent::params::control_center_service_enable,
  $file_limit           = $::confluent::params::control_center_file_limit,
  $manage_repository    = $::confluent::params::manage_repository,
  $stop_timeout_secs    = $::confluent::params::control_center_stop_timeout_secs,
  $heap_size            = $::confluent::params::control_center_heap_size

) inherits confluent::params {
  include ::confluent

  if($manage_repository) {
    include ::confluent::repository
  }

  validate_hash($config)
  validate_hash($environment_settings)
  validate_absolute_path($config_path)
  validate_absolute_path($environment_file)
  validate_absolute_path($log_path)

  $application = 'c3'

  $default_environment_settings = {
    'CONTROL_CENTER_HEAP_OPTS' => {
      'value' => "-Xmx${heap_size}"
    },
    'CONTROL_CENTER_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'LOG_DIR'                  => {
      'value' => $log_path
    }
  }

  $merged_environment_settings = prefix(merge($default_environment_settings, $environment_settings), "${application}/")
  $kafka_environment_variable_defaults = {
    'path'        => $environment_file,
  }

  ensure_resources(
    'confluent::kafka_environment_variable',
    $merged_environment_settings,
    $kafka_environment_variable_defaults
  )

  $control_center_default_settings = {
    'confluent.controlcenter.id'              => {
      'value' => $control_center_id
    },
    'confluent.controlcenter.data.dir'        => {
      'value' => $data_path
    },
    'bootstrap.servers'                       => {
      'value' => join(any2array($bootstrap_servers), ',')
    },
    'confluent.controlcenter.connect.cluster' => {
      'value' => join(any2array($connect_cluster), ',')
    },
    'zookeeper.connect'                       => {
      'value' => join(any2array($zookeeper_connect), ',')
    }
  }

  $merged_control_center_settings = prefix(merge($control_center_default_settings, $config), "${application}/")
  $java_property_defaults = {
    'ensure' => 'present',
    'path'   => $config_path,
  }

  ensure_resources(
    'confluent::java_property',
    $merged_control_center_settings,
    $java_property_defaults
  )

  user { $user:
    ensure => present
  } ->
  file { [$log_path, $data_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    tag     => 'confluent'
  }

  package { 'confluent-control-center':
    ensure => latest,
    tag    => 'confluent',
  }

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => 'Confluent Control Center', },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' => "/usr/bin/control-center-start ${config_path}", },
    # "${service_name}/Service/ExecStop'               => { 'value' => "/usr/bin/zookeeper-server-stop", },
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