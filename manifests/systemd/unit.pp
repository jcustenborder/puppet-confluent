define confluent::systemd::unit (
  $ensure='present',
  $description,
  $exec_start,
  $user,
  $exec_stop=undef,
  $environment_file=undef,
  $file_limit=undef,
  $restart_sec=5
) {
  include ::confluent::systemd

  $service_file = "/usr/lib/systemd/system/${name}.service"

  ini_setting { "${name}/Unit/Description":
    ensure  => 'present',
    path    => $service_file,
    section => 'Unit',
    setting => 'Description',
    value   => $description,
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  ini_setting { "${name}/Unit/Wants":
    ensure  => 'present',
    path    => $service_file,
    section => 'Unit',
    setting => 'Wants',
    value   => 'basic.target',
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  ini_setting { "${name}/Unit/After":
    ensure  => 'present',
    path    => $service_file,
    section => 'Unit',
    setting => 'After',
    value   => 'basic.target network.target',
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  ini_setting { "${name}/Service/User":
    ensure  => 'present',
    path    => $service_file,
    section => 'Service',
    setting => 'User',
    value   => $user
  }

  if($environment_file) {
    ini_setting { "${name}/Service/EnvironmentFile":
      ensure  => 'present',
      path    => $service_file,
      section => 'Service',
      setting => 'EnvironmentFile',
      value   => $environment_file,
      notify => Exec['kafka-systemctl-daemon-reload']
    }
  }

  ini_setting { "${name}/Service/ExecStart":
    ensure  => 'present',
    path    => $service_file,
    section => 'Service',
    setting => 'ExecStart',
    value   => $exec_start,
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  if($exec_stop){
    ini_setting { "${name}/Service/ExecStop":
      ensure  => 'present',
      path    => $service_file,
      section => 'Service',
      setting => 'ExecStop',
      value   => $exec_stop,
      notify  => Exec['kafka-systemctl-daemon-reload']
    }
  }

  if($file_limit) {
    ini_setting { "${name}/Service/LimitNOFILE":
      ensure  => 'present',
      path    => $service_file,
      section => 'Service',
      setting => 'LimitNOFILE',
      value   => $file_limit,
      notify => Exec['kafka-systemctl-daemon-reload']
    }
  }

  ini_setting { "${name}/Service/KillMode":
    ensure  => 'present',
    path    => $service_file,
    section => 'Service',
    setting => 'KillMode',
    value   => 'process',
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  ini_setting { "${name}/Service/RestartSec":
    ensure  => 'present',
    path    => $service_file,
    section => 'Service',
    setting => 'RestartSec',
    value   => $restart_sec,
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  ini_setting { "${name}/Service/Type":
    ensure  => 'present',
    path    => $service_file,
    section => 'Service',
    setting => 'Type',
    value   => 'simple',
    notify => Exec['kafka-systemctl-daemon-reload']
  }

  ini_setting { "${name}/Install/WantedBy":
    ensure  => 'present',
    path    => $service_file,
    section => 'Install',
    setting => 'WantedBy',
    value   => 'multi-user.target',
    notify => Exec['kafka-systemctl-daemon-reload']
  }
}