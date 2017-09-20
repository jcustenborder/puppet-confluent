class confluent::kafka::mirrormaker (
  $user                      = $::confluent::params::mirror_maker_user,
  $log_path                  = $::confluent::params::mirror_maker_log_path,
  $config_root               = $::confluent::params::mirror_maker_config_root,
  $new_consumer              = true,
  $num_streams               = 1,
  $offset_commit_interval_ms = 60000,
  $file_limit                = 32000,
  $service_stop_timeout_secs = 300,
  $manage_service            = true,
  $service_ensure            = 'running',
  $service_enable            = true,
  $environment_settings      = {},
  $heap_size                 = '1g',
  $instances                 = {},
  $manage_repository         = $::confluent::params::manage_repository,
) inherits confluent::params {
  include ::confluent::kafka

  if($manage_repository) {
    include ::confluent::repository
  }

  user { $user:
    ensure => present,
    tag    => 'confluent'
  }

  file { $config_root:
    ensure => directory,
    alias  => 'mirrormaker-log_path',
    owner  => 'root',
    group  => 'root',
    tag    => 'confluent'
  }

  file { $log_path:
    ensure => directory,
    alias  => 'mirrormaker-config_root',
    owner  => 'root',
    group  => 'root',
    tag    => 'confluent'
  }

  $mirror_instance_defaults = {
    'ensure' => 'present'
  }

  ensure_resources('confluent::kafka::mirrormaker::instance', $instances, $mirror_instance_defaults)
}