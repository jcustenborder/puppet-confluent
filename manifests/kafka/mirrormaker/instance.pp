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
  $whitelist                        = [],
  $blacklist                        = ['__consumer-offsets'],
  $queue_size                       = 10000,
  $num_streams                      = 1,
  $new_consumer                     = true,
  $offset_commit_interval_ms        = 60000,
  $service_name                     = "mirrormaker-${title}",
  $user                             = $::confluent::kafka::mirrormaker::mirror_maker_user,
) {
  include ::confluent::kafka::mirrormaker

  validate_re($title, '^[a-zA-Z\d_-]+$')

  $config_directory = "/etc/kafka/mirrormaker/${title}"
  $log_directory = "/var/log/mirrormaker-${title}"


  file { [$config_directory, $log_directory]:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    tag     => 'confluent',
    require => File['/etc/kafka/mirrormaker']
  }

  $unit_ini_setting_defaults = {
    'ensure' => 'present'
  }

  $unit_ini_settings = {
    "${service_name}/Unit/Description"        => { 'value' => "Apache Kafka Mirror Maker - ${title}", },
    "${service_name}/Unit/Wants"              => { 'value' => 'basic.target', },
    "${service_name}/Unit/After"              => { 'value' => 'basic.target network.target', },
    "${service_name}/Service/User"            => { 'value' => $user, },
    "${service_name}/Service/EnvironmentFile" => { 'value' => $environment_file, },
    "${service_name}/Service/ExecStart"       => { 'value' =>
    "/usr/bin/zookeeper-server-start ${config_path}", },
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