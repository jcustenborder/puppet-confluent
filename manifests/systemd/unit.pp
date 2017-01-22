# Define is used to create a SystemD unit for a kafka service.
#
# @param ensure present to create the unit, false to remove it.
# @param description Description of the unit. This is the display name.
# @param exec_start ExecStart line in the SystemD unit. The command that will be executed to start the application.
# @param user The system user to run the service as. User must be defined in puppet.
# @param exec_stop ExecStop line in the SystemD unit. The command that will be executed to stop the application.
# @param environment_file EnvironmentFile line in the SystemD unit. This is the file with environment variables to pass to the application.
# @param file_limit LimitNOFILE line in the SystemD unit. The file handle limit for the process.
# @param restart_sec RestartSec line in the SystemD unit. The number of seconds to delay between ExecStop and ExecStart on a restart.
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

  User[$user] ->
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