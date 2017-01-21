# Class is used to install and configure an Apache Kafka Broker using the Confluent installation packages.
#
# @example Installation through class.
#     class{'confluent::kafka::broker':
#       kafka_settings => {
#         'broker.id' => {
#           'value' => '1'
#         },
#         'zookeeper.connect' => {
#           'value' => 'zookeeper-01.custenborder.com:2181,zookeeper-02.custenborder.com:2181,zookeeper-03.custenborder.com:2181'
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
#     include ::confluent::kafka::broker
#
#     confluent::kafka::broker::kafka_settings:
#       zookeeper.connect:
#         value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#       broker.id:
#         value: 0
#       log.dirs:
#         value: /var/lib/kafka
#       advertised.listeners:
#         value: "PLAINTEXT://%{::fqdn}:9092"
#       delete.topic.enable:
#         value: true
#       auto.create.topics.enable:
#         value: false
#     confluent::kafka::broker::java_settings:
#       KAFKA_HEAP_OPTS:
#         value: -Xmx1024M
#
# @param kafka_user System user to create and run the Kakfa broker. This user will be used to run the service and all kafka directories will be owned by this user.
# @param kafka_settings Settings for the server.properties file.
# @param java_settings Settings to put in the environment file used to pass environment variables to the kafka startup scripts.
# @param broker_properties_path Path to the broker properties file.
class confluent::kafka::broker (
  $kafka_user = 'kafka',
  $kafka_settings = { },
  $java_settings = { },
  $broker_properties_path='/etc/kafka/server.properties'
) {
  include ::confluent::kafka
  validate_hash($kafka_settings)
  validate_hash($java_settings)

  $kafka_default_settings = {
    'log.dirs'          => {
      'value' => '/var/lib/kafka'
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
      'value' => '/var/log/kafka'
    }
  }


  $actual_kafka_settings = merge($kafka_default_settings, $kafka_settings)
  $actual_java_settings = merge($java_default_settings, $java_settings)

  $log_dir = $actual_kafka_settings['log.dirs']['value']
  validate_absolute_path($log_dir)

  $log4j_log_dir = $actual_java_settings['LOG_DIR']['value']
  validate_absolute_path($log4j_log_dir)

  user{ $kafka_user:
    ensure => present
  } ->
  file{ [$log_dir, $log4j_log_dir]:
    ensure  => directory,
    owner   => $kafka_user,
    group   => $kafka_user,
    recurse => true
  }

  $ensure_kafka_settings_defaults={
    'ensure'      => 'present',
    'path'        => $broker_properties_path,
    'application' => 'kafka'
  }

  ensure_resources('confluent::java_property', $actual_kafka_settings, $ensure_kafka_settings_defaults)

  $environment_file='/etc/sysconfig/kafka'

  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => 'kafka'
  }

  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    'kafka/Unit/Description'               => { 'value' => 'Apache Kafka by Confluent', },
    'kafka/Unit/Wants'                     => { 'value' => 'basic.target', },
    'kafka/Unit/After'                     => { 'value' => 'basic.target network.target', },
    'kafka/Service/User'                   => { 'value' => $kafka_user, },
    'kafka/Service/EnvironmentFile'        => { 'value' => $environment_file, },
    'kafka/Service/ExecStart'              => { 'value' => "/usr/bin/kafka-server-start ${broker_properties_path}", },
    'kafka/Service/ExecStop'               => { 'value' => "/usr/bin/kafka-server-stop", },
    'kafka/Service/LimitNOFILE'            => { 'value' => 131072, },
    'kafka/Service/KillMode'               => { 'value' => 'process', },
    'kafka/Service/RestartSec'             => { 'value' => 5, },
    'kafka/Service/Type'                   => { 'value' => 'simple', },
    'kafka/Install/WantedBy'               => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)
}