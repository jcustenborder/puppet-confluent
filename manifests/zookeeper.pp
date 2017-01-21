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
# @param zookeeper_user System user to create and run Zookeeper as. This user will be used to run the service and all zookeeper directories will be owned by this user.
# @param zookeeper_settings Settings for the zookeeper.properties file.
# @param java_settings Settings to put in the environment file used to pass environment variables to the zookeeper startup scripts.
class confluent::zookeeper (
  $zookeeper_user = 'zookeeper',
  $zookeeper_settings = { },
  $java_settings = { }
) {
  validate_hash($zookeeper_settings)
  validate_hash($java_settings)

  $zookeeper_default_settings = {
    'dataDir'                 => {
      'value' => '/var/lib/zookeeper'
    },
    'clientPort'              => {
      'value' => 2181
    },
    'maxClientCnxns'          => {
      'value' => 0
    },
    'initLimit'               => {
      'value' => 5
    },
    'syncLimit'               => {
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
      'value' => '/var/log/zookeeper'
    }
  }



  $actual_zookeeper_settings = merge($zookeeper_default_settings, $zookeeper_settings)
  $actual_java_settings = merge($java_default_settings, $java_settings)

  $log4j_log_dir = $actual_java_settings['LOG_DIR']['value']
  validate_absolute_path($log4j_log_dir)

  $data_dir = $actual_zookeeper_settings['dataDir']['value']
  validate_absolute_path($data_dir)

  $my_id = $actual_zookeeper_settings['myid']['value']
  validate_integer($my_id)
  $myid_file = "${data_dir}/myid"

  user{ $zookeeper_user:
    ensure => present
  } ->
  file{ [$data_dir, $log4j_log_dir]:
    ensure  => directory,
    owner   => $zookeeper_user,
    group   => $zookeeper_user,
    recurse => true
  } ->
  file{ $myid_file:
    ensure  => present,
    content => $my_id,
    mode    => '0644',
    group   => $zookeeper_user,
    owner   => $zookeeper_user
  }

  package{ 'confluent-kafka-2.11':
    alias  => 'zookeeper',
    ensure => latest
  } -> Ini_setting <| tag == 'kafka-setting' |>

  $ensure_zookeeper_settings_defaults={
    'ensure'      => 'present',
    'path'        => '/etc/kafka/zookeeper.properties',
    'application' => 'zookeeper'
  }

  ensure_resources('confluent::java_property', $actual_zookeeper_settings, $ensure_zookeeper_settings_defaults)

  $environment_file='/etc/sysconfig/zookeeper'

  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => 'zookeeper'
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    'zookeeper/Unit/Description'               => { 'value' => 'Apache Zookeeper by Confluent', },
    'zookeeper/Unit/Wants'                     => { 'value' => 'basic.target', },
    'zookeeper/Unit/After'                     => { 'value' => 'basic.target network.target', },
    'zookeeper/Service/User'                   => { 'value' => $zookeeper_user, },
    'zookeeper/Service/EnvironmentFile'        => { 'value' => $environment_file, },
    'zookeeper/Service/ExecStart'              => { 'value' => "/usr/bin/zookeeper-server-start /etc/kafka/zookeeper.properties", },
    'zookeeper/Service/ExecStop'               => { 'value' => "/usr/bin/zookeeper-server-stop", },
    'zookeeper/Service/LimitNOFILE'            => { 'value' => 131072, },
    'zookeeper/Service/KillMode'               => { 'value' => 'process', },
    'zookeeper/Service/RestartSec'             => { 'value' => 5, },
    'zookeeper/Service/Type'                   => { 'value' => 'simple', },
    'zookeeper/Install/WantedBy'               => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)
}