# Class is used to install and configure an Apache Kafka Broker using the Confluent installation packages.
#
# @example Installation through class.
#     class{'confluent::kafka::broker':
#       broker_id => '1',
#       config => {
#         'zookeeper.connect' => {
#           'value' => 'zookeeper-01.custenborder.com:2181,zookeeper-02.custenborder.com:2181,zookeeper-03.custenborder.com:2181'
#         },
#       },
#       environment_settings => {
#         'KAFKA_HEAP_OPTS' => {
#           'value' => '-Xmx4000M'
#         }
#       }
#     }
#
# @example Hiera based installation
#     include ::confluent::kafka::broker
#
#     confluent::kafka::broker::broker_id: '1'
#     confluent::kafka::broker::config:
#       zookeeper.connect:
#         value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
#       log.dirs:
#         value: /var/lib/kafka
#       advertised.listeners:
#         value: "PLAINTEXT://%{::fqdn}:9092"
#       delete.topic.enable:
#         value: true
#       auto.create.topics.enable:
#         value: false
#     confluent::kafka::broker::environment_settings:
#       KAFKA_HEAP_OPTS:
#         value: -Xmx1024M
#
# @param broker_id broker.id of the Kafka broker.
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
class confluent::kafka::broker (
  Integer $broker_id,
  Hash[String, Variant[String, Integer, Boolean]] $config               = {},
  Hash[String, Variant[String, Integer, Boolean]] $logging_config       = $::confluent::params::kafka_logging_config,
  Hash[String, Variant[String, Integer, Boolean]] $environment_settings = {},
  Stdlib::Unixpath $config_path                                         = $::confluent::params::kafka_config_path,
  Stdlib::Unixpath $logging_config_path                                 =
  $::confluent::params::kafka_logging_config_path,
  Stdlib::Unixpath $environment_file                                    = $::confluent::params::kafka_environment_path,
  Variant[Stdlib::Unixpath, Array[Stdlib::Unixpath]] $data_path         = $::confluent::params::kafka_data_path,
  Stdlib::Unixpath $log_path                                            = $::confluent::params::kafka_log_path,
  String $user                                                          = $::confluent::params::kafka_user,
  String $service_name                                                  = $::confluent::params::kafka_service,
  Boolean $manage_service                                               = $::confluent::params::kafka_manage_service,
  Enum['running', 'stopped'] $service_ensure                            = $::confluent::params::kafka_service_ensure,
  Boolean $service_enable                                               = $::confluent::params::kafka_service_enable,
  Integer $file_limit                                                   = $::confluent::params::kafka_file_limit,
  Integer $stop_timeout_secs                                            = $::confluent::params::kafka_stop_timeout_secs,
  Boolean $manage_repository                                            = $::confluent::params::manage_repository,
  String $heap_size                                                     = $::confluent::params::kafka_heap_size,
  Boolean $restart_on_logging_change                                    = true,
  Boolean $restart_on_change                                            = true,
  Variant[String, Array[String]] $zookeeper_connect                     = 'localhost:2181'
) inherits confluent::params {
  include ::confluent
  include ::confluent::kafka

  if($manage_repository) {
    include ::confluent::repository
  }

  $default_config = {
    'broker.id'                                => $broker_id,
    'log.dirs'                                 => join(any2array($data_path), ','),
    'confluent.support.customer.id'            => 'anonymous',
    'confluent.support.metrics.enable'         => true,
    'group.initial.rebalance.delay.ms'         => 0,
    'log.retention.check.interval.ms'          => 300000,
    'log.retention.hours'                      => 168,
    'log.segment.bytes'                        => 1073741824,
    'num.io.threads'                           => 8,
    'num.network.threads'                      => 3,
    'num.partitions'                           => 1,
    'num.recovery.threads.per.data.dir'        => 1,
    'offsets.topic.replication.factor'         => 3,
    'socket.receive.buffer.bytes'              => 102400,
    'socket.request.max.bytes'                 => 104857600,
    'socket.send.buffer.bytes'                 => 102400,
    'transaction.state.log.min.isr'            => 2,
    'transaction.state.log.replication.factor' => 3,
    'zookeeper.connect'                        => join(any2array($zookeeper_connect), ','),
    'zookeeper.connection.timeout.ms'          => 6000,
  }
  $actual_config = merge($default_config, $config)

  confluent::properties { $service_name:
    ensure => present,
    path   => $config_path,
    config => $actual_config
  }

  $default_environment_settings = {
    'KAFKA_HEAP_OPTS'  => "-Xmx${heap_size}",
    'KAFKA_OPTS'       => '-Djava.net.preferIPv4Stack=true',
    'GC_LOG_ENABLED'   => true,
    'LOG_DIR'          => $log_path,
    'KAFKA_LOG4J_OPTS' => "-Dlog4j.configuration=file:${logging_config_path}"
  }
  $actual_environment_settings = merge($default_environment_settings, $environment_settings)

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_file,
    config => $actual_environment_settings
  }

  confluent::logging { $service_name:
    path   => $logging_config_path,
    config => $logging_config
  }

  user { $user:
    ensure => present
  } ->
  file { [$log_path, $data_path]:
    ensure  => directory,
    owner   => $user,
    group   => $user,
    recurse => true,
    recurselimit => 1,
    tag     => '__confluent__'
  }

  confluent::systemd::unit { $service_name:
    config => {
      'Unit'    => {
        'Description' => 'Apache Kafka by Confluent'
      },
      'Service' => {
        'User'            => $user,
        'EnvironmentFile' => $environment_file,
        'ExecStart'       => "/usr/bin/kafka-server-start ${config_path}",
        'ExecStop'        => '/usr/bin/kafka-server-stop',
        'LimitNOFILE'     => $file_limit,
      }
    }
  }

  if($manage_service) {
    service { $service_name:
      ensure => $service_ensure,
      enable => $service_enable,
      tag    => '__confluent__'
    }
    if($restart_on_change) {
      Confluent::Systemd::Unit[$service_name] ~> Service[$service_name]
      Confluent::Environment[$service_name] ~> Service[$service_name]
      Confluent::Properties[$service_name] ~> Service[$service_name]
      if($restart_on_logging_change) {
        Confluent::Logging[$service_name] ~> Service[$service_name]
      }
    }
  }
}
