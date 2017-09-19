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
  $client_id,
  $consumer_config,
  $producer_config,
  $abort_on_send_failure            = true,
  $consumer_rebalance_listener      = undef,
  $consumer_rebalance_listener_args = undef,
  $message_handler                  = undef,
  $message_handler_args             = undef,
  $whitelist                        = undef,
  $blacklist                        = undef,
  $num_streams                      = undef,
  $new_consumer                     = undef,
  $offset_commit_interval_ms        = undef,
  $service_name                     = "mirrormaker-${title}",
  $user                             = undef,
  $file_limit                       = undef,
  $service_stop_timeout_secs        = undef,
  $manage_service                   = undef,
  $service_ensure                   = undef,
  $service_enable                   = undef,
  $environment_settings             = {},
  $heap_size                        = undef
) {
  include ::confluent::kafka::mirrormaker

  validate_re($title, '^[a-zA-Z\d_-]+$')
  validate_hash($consumer_config)
  validate_hash($producer_config)

  if(undef == $whitelist and undef == $blacklist) {
    fail('$blacklist or $whitelist must be specified.')
  }

  $mirror_maker_user = pick($user, $::confluent::kafka::mirrormaker::user)
  $mirror_maker_num_streams = pick($num_streams, $::confluent::kafka::mirrormaker::num_streams)
  $mirror_maker_new_consumer = pick($new_consumer, $::confluent::kafka::mirrormaker::new_consumer)
  $mirror_maker_offset_commit_interval_ms =
    pick($offset_commit_interval_ms, $::confluent::kafka::mirrormaker::offset_commit_interval_ms)
  $mirror_maker_file_limit = pick($file_limit, $::confluent::kafka::mirrormaker::file_limit)
  $mirror_maker_service_stop_timeout_secs =
    pick($service_stop_timeout_secs, $::confluent::kafka::mirrormaker::service_stop_timeout_secs)
  $mirror_maker_manage_service = pick($manage_service, $::confluent::kafka::mirrormaker::manage_service)
  $mirror_maker_service_ensure = pick($service_ensure, $::confluent::kafka::mirrormaker::service_ensure)
  $mirror_maker_service_enable = pick($service_enable, $::confluent::kafka::mirrormaker::service_enable)
  $mirror_maker_environment_settings = pick($environment_settings, $::confluent::kafka::mirrormaker::environment_settings)
  $mirror_maker_heap_size = pick($heap_size, $::confluent::kafka::mirrormaker::heap_size)
  
  $config_directory = "${::confluent::kafka::mirrormaker::config_root}/${title}"
  $producer_config_path = "${config_directory}/producer.properties"
  $consumer_config_path = "${config_directory}/consumer.properties"

  $log_directory = "${::confluent::kafka::mirrormaker::log_path}/${title}"
  $environment_file = "${::confluent::params::mirror_maker_environment_path_prefix}-${title}"

  file { [$config_directory, $log_directory]:
    ensure  => directory,
    owner   => $mirror_maker_user,
    group   => 'root',
    tag     => 'confluent',
    require => [
      File['mirrormaker-log_path'],
      File['mirrormaker-config_root'],
    ]
  }

  $mirror_maker_consumer_settings = prefix($consumer_config, "${service_name}-consumer/")
  $mirror_maker_consumer_setting_defaults = {
    'ensure' => 'present',
    'path'   => $consumer_config_path,
  }
  ensure_resources(
    'confluent::java_property',
    $mirror_maker_consumer_settings,
    $mirror_maker_consumer_setting_defaults
  )

  $mirror_maker_producer_settings = prefix($producer_config, "${service_name}-producer/")
  $mirror_maker_producer_setting_defaults = {
    'ensure' => 'present',
    'path'   => $producer_config_path,
  }
  ensure_resources(
    'confluent::java_property',
    $mirror_maker_producer_settings,
    $mirror_maker_producer_setting_defaults
  )
  

  $java_default_settings = {
    'KAFKA_HEAP_OPTS' => {
      'value' => "-Xmx${mirror_maker_heap_size}"
    },
    'KAFKA_OPTS'      => {
      'value' => '-Djava.net.preferIPv4Stack=true'
    },
    'GC_LOG_ENABLED'  => {
      'value' => true
    },
    'LOG_DIR'         => {
      'value' => $log_directory
    }
  }

  $actual_java_settings = prefix(merge($java_default_settings, $mirror_maker_environment_settings), "${service_name}/")
  $ensure_java_settings_defaults = {
    'path' => $environment_file,
  }
  ensure_resources('confluent::kafka_environment_variable', $actual_java_settings, $ensure_java_settings_defaults)

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $commandline = template('confluent/kafka/mirrormaker/commandline.erb')

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => "Apache Kafka Mirror Maker - ${title}", },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network-online.target', },
    "${service_name}/Service/User"            => { 'value' => $mirror_maker_user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' => $commandline, },
    "${service_name}/Service/LimitNOFILE"     => { 'value' => $mirror_maker_file_limit, },
    "${service_name}/Service/KillMode"        => { 'value' => 'process', },
    "${service_name}/Service/RestartSec"      => { 'value' => 5, },
    "${service_name}/Service/TimeoutStopSec"  => { 'value' => $mirror_maker_service_stop_timeout_secs, },
    "${service_name}/Service/Type"            => { 'value' => 'simple', },
    "${service_name}/Install/WantedBy"        => { 'value' => 'multi-user.target', },
  }

  ensure_resources('confluent::systemd::unit_ini_setting', $unit_ini_settings, $unit_ini_setting_defaults)

  if($mirror_maker_manage_service) {
    service { $service_name:
      ensure => $mirror_maker_service_ensure,
      enable => $mirror_maker_service_enable,
      tag    => 'confluent'
    }
    Ini_setting<| tag == "confluent-${service_name}" |> ~> Service[$service_name]
    Ini_subsetting<| tag == "confluent-${service_name}" |> ~> Service[$service_name]
  }
}