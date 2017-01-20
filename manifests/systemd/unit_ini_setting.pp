define confluent::systemd::unit_ini_setting($ensure, $value=undef){
  include ::confluent::systemd
  validate_re($name, '^[\w-]+\/[\w]+\/[\w]+$')
  $name_parts=split($name, '/')
  $unit_name = $name_parts[0]
  $section = $name_parts[1]
  $setting = $name_parts[2]

  $service_file="/usr/lib/systemd/system/${unit_name}.service"

  case $ensure {
    'present': {
      if($value == undef) {
        fail("When ensure is present a value is required.")
      }

      ini_setting { $name:
        ensure  => $ensure,
        path    => $service_file,
        section => $section,
        setting => $setting,
        value   => $value,
        notify  => Exec['kafka-systemctl-daemon-reload']
      }
    }
    'absent': {
      ini_setting { $name:
        ensure  => $ensure,
        path    => $service_file,
        section => $section,
        setting => $setting,
        notify  => Exec['kafka-systemctl-daemon-reload']
      }
    }
    default: {
      fail('ensure must be absent or present')
    }
  }
}