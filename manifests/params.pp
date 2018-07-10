# Default parameters for the installation.
#
#
class confluent::params {
  $confluent_version = '4.0'
  $manage_repository = true
  $connect_distributed_user = 'connect-distributed'
  $connect_distributed_service = 'connect-distributed'
  $connect_distributed_manage_service = true
  $connect_distributed_service_ensure = 'running'
  $connect_distributed_service_enable = true
  $connect_distributed_file_limit = 128000
  $connect_distributed_config_path = '/etc/kafka/connect-distributed.properties'
  $connect_distributed_logging_config_path = '/etc/kafka/connect-distributed.logging.properties'
  $connect_distributed_log_path = '/var/log/kafka-connect-distributed'
  $connect_distributed_stop_timeout_secs = 300
  $connect_distributed_heap_size = '512m'
  $connect_distributed_restart_on_logging_change = true
  $connect_distributed_restart_on_change = true
  $connect_distributed_config_storage_topic_replication_factor = 3
  $connect_distributed_config_storage_topic_name = '_connect_configs'
  $connect_distributed_offset_storage_topic_replication_factor = 3
  $connect_distributed_offset_storage_topic_name = '_connect_offsets'
  $connect_distributed_status_storage_topic_replication_factor = 3
  $connect_distributed_status_storage_topic_name = '_connect_status'
  $connect_distributed_group_id = 'connect-cluster'
  $connect_distributed_plugin_path = [
    '/usr/share/java'
  ]
  $connect_distributed_key_converter = 'org.apache.kafka.connect.json.JsonConverter'
  $connect_distributed_value_converter = 'org.apache.kafka.connect.json.JsonConverter'

  $connect_standalone_user = 'connect-standalone'
  $connect_standalone_service = 'connect-standalone'
  $connect_standalone_manage_service = true
  $connect_standalone_service_ensure = 'running'
  $connect_standalone_service_enable = true
  $connect_standalone_file_limit = 128000
  $connect_standalone_config_path = '/etc/kafka/connect-standalone.properties'
  $connect_standalone_logging_config_path = '/etc/kafka/connect-standalone.logging.properties'
  $connect_standalone_log_path = '/var/log/kafka-connect-standalone'
  $connect_standalone_stop_timeout_secs = 300
  $connect_standalone_heap_size = '512m'
  $connect_standalone_offset_storage_path = '/var/lib/kafka-connect-standalone'
  $connect_standalone_restart_on_logging_change = true
  $connect_standalone_restart_on_change = true
  $connect_standalone_plugin_path = [
    '/usr/share/java'
  ]
  $connect_standalone_key_converter = 'org.apache.kafka.connect.json.JsonConverter'
  $connect_standalone_value_converter = 'org.apache.kafka.connect.json.JsonConverter'

  $kafka_user = 'kafka'
  $kafka_service = 'kafka'
  $kafka_manage_service = true
  $kafka_service_ensure = 'running'
  $kafka_service_enable = true
  $kafka_file_limit = 128000
  $kafka_config_path = '/etc/kafka/server.properties'
  $kafka_logging_config_path = '/etc/kafka/server.logging.properties'
  $kafka_log_path = '/var/log/kafka'
  $kafka_data_path = '/var/lib/kafka'
  $kafka_stop_timeout_secs = 300
  $kafka_heap_size = '1024m'
  $kafka_logging_config = {
    'log4j.rootLogger'                                   => 'INFO, stdout, roller, authorizer',
    'log4j.appender.stdout'                              => 'org.apache.log4j.ConsoleAppender',
    'log4j.appender.stdout.layout'                       => 'org.apache.log4j.PatternLayout',
    'log4j.appender.stdout.layout.ConversionPattern'     => '[%d] %p %m (%c)%n',
    'log4j.appender.roller'                              => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.roller.MaxFileSize'                  => '100MB',
    'log4j.appender.roller.MaxBackupIndex'               => '10',
    'log4j.appender.roller.File'                         => '${kafka.logs.dir}/server.log',
    'log4j.appender.roller.layout'                       => 'org.apache.log4j.PatternLayout',
    'log4j.appender.roller.layout.ConversionPattern'     => '[%d] %p %m (%c)%n',
    'log4j.appender.state'                               => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.state.MaxFileSize'                   => '100MB',
    'log4j.appender.state.MaxBackupIndex'                => '10',
    'log4j.appender.state.File'                          => '${kafka.logs.dir}/state-change.log',
    'log4j.appender.state.layout'                        => 'org.apache.log4j.PatternLayout',
    'log4j.appender.state.layout.ConversionPattern'      => '[%d] %p %m (%c)%n',
    'log4j.appender.request'                             => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.request.MaxFileSize'                 => '100MB',
    'log4j.appender.request.MaxBackupIndex'              => '10',
    'log4j.appender.request.File'                        => '${kafka.logs.dir}/kafka-request.log',
    'log4j.appender.request.layout'                      => 'org.apache.log4j.PatternLayout',
    'log4j.appender.request.layout.ConversionPattern'    => '[%d] %p %m (%c)%n',
    'log4j.appender.cleaner'                             => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.cleaner.MaxFileSize'                 => '100MB',
    'log4j.appender.cleaner.MaxBackupIndex'              => '10',
    'log4j.appender.cleaner.File'                        => '${kafka.logs.dir}/log-cleaner.log',
    'log4j.appender.cleaner.layout'                      => 'org.apache.log4j.PatternLayout',
    'log4j.appender.cleaner.layout.ConversionPattern'    => '[%d] %p %m (%c)%n',
    'log4j.appender.controller'                          => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.controller.MaxFileSize'              => '100MB',
    'log4j.appender.controller.MaxBackupIndex'           => '10',
    'log4j.appender.controller.File'                     => '${kafka.logs.dir}/controller.log',
    'log4j.appender.controller.layout'                   => 'org.apache.log4j.PatternLayout',
    'log4j.appender.controller.layout.ConversionPattern' => '[%d] %p %m (%c)%n',
    'log4j.appender.authorizer'                          => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.authorizer.MaxFileSize'              => '100MB',
    'log4j.appender.authorizer.MaxBackupIndex'           => '10',
    'log4j.appender.authorizer.File'                     => '${kafka.logs.dir}/kafka-authorizer.log',
    'log4j.appender.authorizer.layout'                   => 'org.apache.log4j.PatternLayout',
    'log4j.appender.authorizer.layout.ConversionPattern' => '[%d] %p %m (%c)%n',
    'log4j.logger.org.I0Itec.zkclient.ZkClient'          => 'INFO',
    'log4j.logger.org.apache.zookeeper'                  => 'INFO',
    'log4j.logger.kafka'                                 => 'INFO',
    'log4j.logger.org.apache.kafka'                      => 'INFO',
    'log4j.logger.kafka.request.logger'                  => 'WARN, request',
    'log4j.additivity.kafka.request.logger'              => false,
    'log4j.logger.kafka.network.RequestChannel$'         => 'WARN, request',
    'log4j.additivity.kafka.network.RequestChannel$'     => false,
    'log4j.logger.kafka.controller'                      => 'TRACE, controller',
    'log4j.additivity.kafka.controller'                  => false,
    'log4j.logger.kafka.log.LogCleaner'                  => 'INFO, cleaner',
    'log4j.additivity.kafka.log.LogCleaner'              => false,
    'log4j.logger.state.change.logger'                   => 'TRACE, state',
    'log4j.additivity.state.change.logger'               => false,
    'log4j.logger.kafka.authorizer.logger'               => 'WARN, authorizer',
    'log4j.additivity.kafka.authorizer.logger'           => false,
    }

  $zookeeper_user = 'zookeeper'
  $zookeeper_service = 'zookeeper'
  $zookeeper_manage_service = true
  $zookeeper_service_ensure = 'running'
  $zookeeper_service_enable = true
  $zookeeper_file_limit = 128000
  $zookeeper_config_path = '/etc/kafka/zookeeper.properties'
  $zookeeper_logging_config_path = '/etc/kafka/zookeeper.logging.properties'
  $zookeeper_log_path = '/var/log/zookeeper'
  $zookeeper_data_path = '/var/lib/zookeeper'
  $zookeeper_stop_timeout_secs = 300
  $zookeeper_heap_size = '512m'

  $schema_registry_user = 'schema-registry'
  $schema_registry_service = 'schema-registry'
  $schema_registry_manage_service = true
  $schema_registry_service_ensure = 'running'
  $schema_registry_service_enable = true
  $schema_registry_file_limit = 128000
  $schema_registry_config_path = '/etc/schema-registry/schema-registry.properties'
  $schema_registry_logging_config_path = '/etc/schema-registry/schema-registry.logging.properties'
  $schema_registry_log_path = '/var/log/schema-registry'
  $schema_registry_stop_timeout_secs = 300
  $schema_registry_heap_size = '512m'

  $ksql_user = 'ksql'
  $ksql_service = 'ksql'
  $ksql_manage_service = true
  $ksql_service_ensure = 'running'
  $ksql_service_enable = true
  $ksql_file_limit = 128000
  $ksql_config_path = '/etc/ksql/ksql-server.properties'
  $ksql_logging_config_path = '/etc/ksql/ksql-server.logging.properties'
  $ksql_log_path = '/var/log/ksql'
  $ksql_stop_timeout_secs = 300
  $ksql_heap_size = '512m'

  $control_center_user = 'control-center'
  $control_center_service = 'control-center'
  $control_center_manage_service = true
  $control_center_service_ensure = 'running'
  $control_center_service_enable = true
  $control_center_file_limit = 128000
  $control_center_config_path = '/etc/confluent-control-center/control-center.properties'
  $control_center_logging_config_path = '/etc/confluent-control-center/control-center.logging.properties'
  $control_center_log_path = '/var/log/control-center'
  $control_center_data_path = '/var/lib/control-center'
  $control_center_stop_timeout_secs = 300
  $control_center_heap_size = '3096m'

  $kafka_package_name = 'confluent-kafka-2.11'

  $mirror_maker_user = 'mirrormaker'
  $mirror_maker_service_prefix = 'mirrormaker-'
  $mirror_maker_log_path = '/var/log/mirrormaker'
  $mirror_maker_config_root = '/etc/kafka/mirrormaker'

  case $::osfamily {
    'RedHat': {
      $connect_distributed_environment_path = '/etc/sysconfig/kafka-connect-distributed'
      $connect_standalone_environment_path = '/etc/sysconfig/kafka-connect-standalone'
      $kafka_environment_path = '/etc/sysconfig/kafka'
      $zookeeper_environment_path = '/etc/sysconfig/zookeeper'
      $schema_registry_environment_path = '/etc/sysconfig/schema-registry'
      $control_center_environment_path = '/etc/sysconfig/control-center'
      $ksql_environment_path = '/etc/sysconfig/ksql'
      $mirror_maker_environment_path_prefix = '/etc/sysconfig/mirrormaker-'

      case $::operatingsystemmajrelease {
        '7': {
          $dist_repository_url = "http://packages.confluent.io/rpm/${confluent_version}/7"
          $repository_url = "http://packages.confluent.io/rpm/${confluent_version}"
          $gpgkey_url = "http://packages.confluent.io/rpm/${confluent_version}/archive.key"
        }
        default: {
          fail("${::operatingsystem} ${::operatingsystemmajrelease} is not supported.")
        }
      }
    }
    'Debian': {
      $connect_distributed_environment_path = '/etc/default/kafka-connect-distributed'
      $connect_standalone_environment_path = '/etc/default/kafka-connect-standalone'
      $kafka_environment_path = '/etc/default/kafka'
      $zookeeper_environment_path = '/etc/default/zookeeper'
      $schema_registry_environment_path = '/etc/default/schema-registry'
      $control_center_environment_path = '/etc/default/control-center'
      $ksql_environment_path = '/etc/default/ksql'
      $mirror_maker_environment_path_prefix = '/etc/default/mirrormaker-'

      $key_url = "http://packages.confluent.io/deb/${confluent_version}/archive.key"
      $repository_url = "http://packages.confluent.io/deb/${confluent_version}"
    }
    default: {
      fail("${::osfamily} is not currently supported.")
    }
  }


}
