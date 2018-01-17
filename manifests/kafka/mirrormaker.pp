class confluent::kafka::mirrormaker (
  String $user                               = $::confluent::params::mirror_maker_user,
  Stdlib::Unixpath $log_path             = $::confluent::params::mirror_maker_log_path,
  Stdlib::Unixpath $config_root          = $::confluent::params::mirror_maker_config_root,
  Boolean $abort_on_send_failure             = true,
  Boolean $new_consumer                      = true,
  Integer $num_streams                       = 1,
  Integer $offset_commit_interval_ms         = 60000,
  Integer $file_limit                        = 32000,
  Integer $service_stop_timeout_secs         = 300,
  Boolean $manage_service                    = true,
  Enum['running', 'stopped'] $service_ensure = 'running',
  Boolean $service_enable                    = true,
  Hash $environment_settings                 = {},
  String $heap_size                          = '1g',
  Hash $instances                            = {},
  Boolean $manage_repository                 = $::confluent::params::manage_repository,
) inherits confluent::params {
  include ::confluent::kafka

  if($manage_repository) {
    include ::confluent::repository
  }

  user { $user:
    ensure => present,
    tag    => '__confluent__'
  }

  file { $config_root:
    ensure => directory,
    alias  => 'mirrormaker-log_path',
    owner  => 'root',
    group  => 'root',
    tag    => '__confluent__'
  }

  file { $log_path:
    ensure => directory,
    alias  => 'mirrormaker-config_root',
    owner  => 'root',
    group  => 'root',
    tag    => '__confluent__'
  }

  $mirror_instance_defaults = {
    'ensure' => 'present'
  }

  ensure_resources('confluent::kafka::mirrormaker::instance', $instances, $mirror_instance_defaults)
}
