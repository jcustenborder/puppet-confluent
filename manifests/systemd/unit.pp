define confluent::systemd::unit (
  Hash $config
) {
  include ::confluent::systemd

  $default_config = {
    'Unit'    => {
      'Wants' => 'basic.target',
      'After' => 'basic.target network-online.target'
    },
    'Service' => {
      'KillMode'       => 'process',
      'RestartSec'     => 5,
      'TimeoutStopSec' => 300,
      'Type'           => 'simple'
    },
    'Install' => {
      'WantedBy' => 'multi-user.target'
    }
  }

  $systemd_config = deep_merge($default_config, $config)
  $service_file = "/usr/lib/systemd/system/${title}.service"

  file { $service_file:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('confluent/systemd.erb')
  }
}