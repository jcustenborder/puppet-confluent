# Class is used to install
#
# @example Installation through class.
#     class{'confluent::kafka::connect::distributed':
#       connect_settings => {
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
#       java_settings => {
#         'KAFKA_HEAP_OPTS' => {
#           'value' => '-Xmx4000M'
#         }
#       }
#     }
#
# @example Hiera based installation
#     include ::confluent::kafka::connect::distributed
#
#      confluent::kafka::connect::distributed::connect_settings:
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
#      confluent::kafka::connect::distributed::connect_settings:java_settings:
#        KAFKA_HEAP_OPTS:
#          value: '-Xmx4000M'
#
# @param connect_settings Settings to pass to the Kafka Connect properties file.
# @param java_settings Settings to put in the environment file used to pass environment variables to the kafka startup scripts.
# @param connect_properties_path Path to the connect properties file.
class confluent::kafka::connect::distributed (
  $connect_settings = { },
  $java_settings = { },
  $connect_properties_path='/etc/kafka/connect-distributed.properties'
) {
  include ::confluent::kafka::connect

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

  $actual_connect_settings = merge($kafka_default_settings, $connect_settings)
  $actual_java_settings = merge($java_default_settings, $java_settings)

  $ensure_connect_settings_defaults={
    'ensure'      => 'present',
    'path'        => $connect_properties_path,
    'application' => 'connect-distributed'
  }

  ensure_resources('confluent::java_property', $actual_connect_settings, $ensure_connect_settings_defaults)

  $environment_file='/etc/sysconfig/kafka-connect-distributed'

  $ensure_java_settings_defaults = {
    'path'        => $environment_file,
    'application' => 'kafka'
  }

  ensure_resources('confluent::java_setting', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    'kafka-connect-distributed/Unit/Description'               => { 'value' => 'Apache Kafka Connect by Confluent', },
    'kafka-connect-distributed/Unit/Wants'                     => { 'value' => 'basic.target', },
    'kafka-connect-distributed/Unit/After'                     => { 'value' => 'basic.target network.target', },
    'kafka-connect-distributed/Service/User'                   => { 'value' => $::confluent::kafka::connect::connect_user, },
    'kafka-connect-distributed/Service/EnvironmentFile'        => { 'value' => $environment_file, },
    'kafka-connect-distributed/Service/ExecStart'              => { 'value' => "/usr/bin/connect-distributed ${connect_properties_path}", },
    'kafka-connect-distributed/Service/LimitNOFILE'            => { 'value' => 131072, },
    'kafka-connect-distributed/Service/KillMode'               => { 'value' => 'process', },
    'kafka-connect-distributed/Service/RestartSec'             => { 'value' => 5, },
    'kafka-connect-distributed/Service/Type'                   => { 'value' => 'simple', },
    'kafka-connect-distributed/Install/WantedBy'               => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)
}