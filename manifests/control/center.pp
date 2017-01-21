# Class is used to install
#
# @example Installation through class.
#     class {'confluent::control::center':
#       control_center_settings => {
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
#       java_settings => {
#         'CONTROL_CENTER_HEAP_OPTS' => {
#           'value' => '-Xmx6g'
#         }
#       }
#     }
#
# @example Hiera based installation
#      include ::confluent::control::center
#
#      confluent::control::center::control_center_settings:
#        zookeeper.connect:
#          value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#        bootstrap.servers:
#          value: 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
#        confluent.controlcenter.connect.cluster:
#          value: 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083'
#      confluent::control::center::java_settings:
#        CONTROL_CENTER_HEAP_OPTS:
#          value: -Xmx6g
#
# @param control_center_user System user to run Confluent Control Center as.
# @param control_center_settings Settings to put in the environment file used to pass environment variables to the Confluent Control Center startup scripts.
# @param java_settings Path to the connect properties file.
# @param control_center_properties_path Path to the properties file for Confluent Control Center
class confluent::control::center (
  $control_center_user = 'c3',
  $control_center_settings = { },
  $java_settings = { },
  $control_center_properties_path='/etc/kafka/server.properties'
) {
  validate_hash($control_center_settings)
  validate_hash($java_settings)

  $control_center_default_settings = {
    'confluent.controlcenter.id' => {
      'value' => 1
    }
  }

  $java_default_settings = {
    'CONTROL_CENTER_HEAP_OPTS' => {
      'value' => '-Xmx3g'
    },
    'CONTROL_CENTER_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'LOG_DIR'         => {
      'value' => '/var/log/control-center'
    }
  }


  $actual_control_center_settings = merge($control_center_default_settings, $control_center_settings)
  $actual_java_settings = merge($java_default_settings, $java_settings)

  $log4j_log_dir = $actual_java_settings['LOG_DIR']['value']
  validate_absolute_path($log4j_log_dir)

  user{ $control_center_user:
    ensure => present
  } ->
  file{ [$log4j_log_dir]:
    ensure  => directory,
    owner   => $control_center_user,
    group   => $control_center_user,
    recurse => true
  }

  package{ 'confluent-control-center':
    alias  => 'control-center',
    ensure => latest
  } -> Ini_setting <| tag == 'kafka-setting' |> -> Ini_subsetting <| tag == 'control-center-setting' |>

  $ensure_control_center_settings_defaults={
    'ensure' => 'present',
    'path'   => $control_center_properties_path,
    'application' => 'control-center'
  }

  ensure_resources('confluent::java_property', $actual_control_center_settings, $ensure_control_center_settings_defaults)

  $environment_file='/etc/sysconfig/control-center'


  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => 'control-center'
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    'confluent-control-center/Unit/Description'               => { 'value' => 'Confluent Control Center', },
    'confluent-control-center/Unit/Wants'                     => { 'value' => 'basic.target', },
    'confluent-control-center/Unit/After'                     => { 'value' => 'basic.target network.target', },
    'confluent-control-center/Service/User'                   => { 'value' => $control_center_user, },
    'confluent-control-center/Service/EnvironmentFile'        => { 'value' => $environment_file, },
    'confluent-control-center/Service/ExecStart'              => { 'value' => "/usr/bin/control-center-start /etc/confluent-control-center/control-center.properties", },
    # 'confluent-control-center/Service/ExecStop'               => { 'value' => "/usr/bin/zookeeper-server-stop", },
    'confluent-control-center/Service/LimitNOFILE'            => { 'value' => 131072, },
    'confluent-control-center/Service/KillMode'               => { 'value' => 'process', },
    'confluent-control-center/Service/RestartSec'             => { 'value' => 5, },
    'confluent-control-center/Service/Type'                   => { 'value' => 'simple', },
    'confluent-control-center/Install/WantedBy'               => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)
}