# A define to manipulate java properties.
#
# @example Setting a property.
#   confluent::java_property{'log.dirs':
#     ensure      => present,
#     path        => '/etc/kafka/server.properties',
#     value       => '/var/lib/kafka',
#     application => 'kafka'
#   }
# @param ensure present to add the property. absent to remove the property.
# @param value The value to be set.
# @param path The path to the file containing the java property.
# @param application The application requesting the change. Property names are often duplicated. This ensures a unique resource name
define confluent::java_property (
  Stdlib::Absolutepath $path,
  Enum['present', 'absent'] $ensure = 'present',
  Any $value  = unset,
) {
  validate_re($name, '^[^\/]+\/.+$')
  validate_absolute_path($path)

  $name_parts = split($name, '/')
  $application = $name_parts[0]
  $property = $name_parts[1]

  ini_setting { $name:
    ensure  => $ensure,
    path    => $path,
    section => '',
    setting => $property,
    value   => $value,
    tag     => ['confluent', "confluent-${application}"],
  }
}