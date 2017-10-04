# --abort.on.send.failure <String: Stop    Configure the mirror maker to exit on
# the entire mirror maker when a send      a failed send. (default: true)
# failure occurs>

#   --blacklist <String: Java regex          Blacklist of topics to mirror. Only
# (String)>                                old consumer supports blacklist.

# --consumer.config <String: config file>  Embedded consumer config for consuming
# from the source cluster.

#   --consumer.rebalance.listener <String:   The consumer rebalance listener to use
# A custom rebalance listener of type      for mirror maker consumer.
# ConsumerRebalanceListener>

#   --help                                   Print this message.

#   --message.handler <String: A custom      Message handler which will process
# message handler of type                  every record in-between consumer and
#   MirrorMakerMessageHandler>               producer.

#   --message.handler.args <String:          Arguments used by custom message
# Arguments passed to message handler      handler for mirror maker.
#   constructor.>

#   --new.consumer                           Use new consumer in mirror maker (this
#   is the default).

#   --num.streams <Integer: Number of        Number of consumption streams.
# threads>                                 (default: 1)

#   --offset.commit.interval.ms <Integer:    Offset commit interval in ms.
#   offset commit interval in                (default: 60000)
# millisecond>

# --producer.config <String: config file>  Embedded producer config.

#   --rebalance.listener.args <String:       Arguments used by custom rebalance
# Arguments passed to custom rebalance     listener for mirror maker consumer.
# listener constructor as a string.>

# --whitelist <String: Java regex          Whitelist of topics to mirror.
# (String)>

define confluent::kafka::mirrormaker::instance (
  Hash $consumer_config,
  Hash $producer_config,
  Enum['present', 'absent'] $ensure                          = 'present',
  Variant[Undef, Boolean] $abort_on_send_failure             = undef,
  Variant[Undef, String] $consumer_rebalance_listener        = undef,
  Variant[Undef, String] $consumer_rebalance_listener_args   = undef,
  Variant[Undef, String] $message_handler                    = undef,
  Variant[Undef, String] $message_handler_args               = undef,
  Variant[Undef, Regexp, String] $whitelist                  = undef,
  Variant[Undef, Regexp, String] $blacklist                  = undef,
  Variant[Undef, Integer] $num_streams                       = undef,
  Variant[Undef, Boolean] $new_consumer                      = undef,
  Variant[Undef, Integer] $offset_commit_interval_ms         = undef,
  Variant[Undef, String] $service_name                       = "mirrormaker-${title}",
  Variant[Undef, String] $user                               = undef,
  Variant[Undef, Integer] $file_limit                        = undef,
  Variant[Undef, Integer] $service_stop_timeout_secs         = undef,
  Variant[Undef, Boolean] $manage_service                    = undef,
  Variant[Undef, Enum['running', 'stopped']] $service_ensure = undef,
  Variant[Undef, Boolean] $service_enable                    = undef,
  Hash $environment_settings                                 = {},
  Undef $heap_size                                           = undef
) {
  include ::confluent::kafka::mirrormaker

  if(undef == $whitelist and undef == $blacklist) {
    fail('$blacklist or $whitelist must be specified.')
  }

  $mm_abort_on_send_failure = pick($abort_on_send_failure, $::confluent::kafka::mirrormaker::abort_on_send_failure)
  $mm_user = pick($user, $::confluent::kafka::mirrormaker::user)
  $mm_num_streams = pick($num_streams, $::confluent::kafka::mirrormaker::num_streams)
  $mm_new_consumer = pick($new_consumer, $::confluent::kafka::mirrormaker::new_consumer)
  $mm_offset_commit_interval_ms =
    pick($offset_commit_interval_ms, $::confluent::kafka::mirrormaker::offset_commit_interval_ms)
  $mm_file_limit = pick($file_limit, $::confluent::kafka::mirrormaker::file_limit)
  $mm_service_stop_timeout_secs =
    pick($service_stop_timeout_secs, $::confluent::kafka::mirrormaker::service_stop_timeout_secs)
  $mm_manage_service = pick($manage_service, $::confluent::kafka::mirrormaker::manage_service)
  $mm_service_ensure = pick($service_ensure, $::confluent::kafka::mirrormaker::service_ensure)
  $mm_service_enable = pick($service_enable, $::confluent::kafka::mirrormaker::service_enable)
  $mm_environment_settings =
    pick($environment_settings, $::confluent::kafka::mirrormaker::environment_settings)
  $mm_heap_size = pick($heap_size, $::confluent::kafka::mirrormaker::heap_size)

  $config_directory = "${::confluent::kafka::mirrormaker::config_root}/${title}"
  $producer_config_path = "${config_directory}/producer.properties"
  $consumer_config_path = "${config_directory}/consumer.properties"
  $logging_config_path = "${config_directory}/logging.properties"

  $log_directory = "${::confluent::kafka::mirrormaker::log_path}/${title}"
  $environment_file = "${::confluent::params::mirror_maker_environment_path_prefix}-${title}"

  file { [$config_directory, $log_directory]:
    ensure  => directory,
    owner   => $mm_user,
    group   => 'root',
    tag     => 'confluent',
    require => [
      File['mirrormaker-log_path'],
      File['mirrormaker-config_root'],
    ]
  }

  confluent::properties{"${service_name}-consumer":
    ensure => present,
    path => $consumer_config_path,
    config => $consumer_config
  }

  confluent::properties{"${service_name}-producer":
    ensure => present,
    path => $producer_config_path,
    config => $producer_config
  }

  $java_default_settings = {
    'KAFKA_HEAP_OPTS' => "-Xmx${mm_heap_size}",
    'KAFKA_OPTS'      => '-Djava.net.preferIPv4Stack=true',
    'GC_LOG_ENABLED'  => true,
    'LOG_DIR'         => $log_directory,
    'KAFKA_LOG4J_OPTS' => "-Dlog4j.configuration=file:${logging_config_path}"
  }

  confluent::logging { $service_name:
    path => $logging_config_path
  }

  $actual_environment_settings = prefix(merge($java_default_settings, $mm_environment_settings), "${service_name}/")

  confluent::environment { $service_name:
    ensure => present,
    path   => $environment_file,
    config => $actual_environment_settings
  }

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $commandline = template('confluent/kafka/mirrormaker/commandline.erb')

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => "Apache Kafka Mirror Maker - ${title}", },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network-online.target', },
    "${service_name}/Service/User"            => { 'value' => $mm_user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' => $commandline, },
    "${service_name}/Service/LimitNOFILE"     => { 'value' => $mm_file_limit, },
    "${service_name}/Service/KillMode"        => { 'value' => 'process', },
    "${service_name}/Service/RestartSec"      => { 'value' => 5, },
    "${service_name}/Service/TimeoutStopSec"  => { 'value' => $mm_service_stop_timeout_secs, },
    "${service_name}/Service/Type"            => { 'value' => 'simple', },
    "${service_name}/Install/WantedBy"        => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)

  if($mm_manage_service) {
    service { $service_name:
      ensure => $mm_service_ensure,
      enable => $mm_service_enable,
      tag    => 'confluent'
    }
    Ini_setting<| tag == "confluent-${service_name}" |> ~> Service[$service_name]
    Ini_subsetting<| tag == "confluent-${service_name}" |> ~> Service[$service_name]
  }
}