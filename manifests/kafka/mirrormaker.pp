class confluent::kafka::mirrormaker (
  $user = $::confluent::params::mirror_maker_user,
  $log_path = $::confluent::params::mirror_maker_log_path,
  $config_root = $::confluent::params::mirror_maker_config_root,
) inherits confluent::params {
  include ::confluent::kafka

  file {$config_root:
    ensure => directory,
    alias  => 'mirrormaker-log_path',
    owner  => 'root',
    group  => 'root',
    tag    => 'confluent'
  }

  file {$log_path:
    ensure => directory,
    alias  => 'mirrormaker-config_root',
    owner  => 'root',
    group  => 'root',
    tag    => 'confluent'
  }
}