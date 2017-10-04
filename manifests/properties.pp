define confluent::properties (
  $ensure,
  Stdlib::Unixpath $path,
  $mode         = '0644',
  String $owner = 'root',
  String $group = 'root',
  Hash $config
) {
  case $ensure {
    'present': {
      file { $path:
        ensure  => $ensure,
        mode    => $mode,
        owner   => $owner,
        group   => $group,
        tag     => "confluent-${title}",
        content => template('confluent/properties.erb')
      }
    }
  }
}