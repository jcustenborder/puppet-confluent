define confluent::environment (
  Enum['present', 'absent'] $ensure,
  Hash[String, Variant[String, Integer, Boolean]] $config,
  Stdlib::Unixpath $path,
  $mode         = '0644',
  String $owner = 'root',
  String $group = 'root',
) {
  case $ensure {
    'present': {
      file { $path:
        ensure  => $ensure,
        mode    => $mode,
        owner   => $owner,
        group   => $group,
        tag     => "confluent-${title}",
        content => template('confluent/environment.erb')
      }
    }
    'absent': {
      file { $path:
        ensure => $ensure
      }
    }
    default: {
      fail("''${ensure}' is not a valid value for ensure. Valid values are present or absent.")
    }
  }
}