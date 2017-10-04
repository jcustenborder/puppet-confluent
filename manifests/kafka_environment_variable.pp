# A define to manage the environemnt files used for launching Kafka. This would most likely be JVM settings.
#
# @example Setting a property.
#   confluent::kafka_environment_variable{'KAFKA_HEAP_OPTS':
#     ensure      => present,
#     path        => '/etc/sysconfig/kafka',
#     value       => '-Xmx4000M',
#     application => 'kafka'
#   }
# @param ensure present to add the property. absent to remove the property.
# @param path The path to the file containing the java property.
# @param value The value to be set.
# @param application The application requesting the change. Property names are often duplicated. This ensures a unique resource name
define confluent::kafka_environment_variable (
  Stdlib::Unixpath $path,
  Enum['present', 'absent'] $ensure = 'present',
  Any $value                        = undef,
) {
  $name_parts = split($name, '/')
  $application = $name_parts[0]
  $property = $name_parts[1]

  ini_subsetting { $name:
    ensure            => $ensure,
    path              => $path,
    section           => '',
    setting           => $property,
    subsetting        => '',
    key_val_separator => '=',
    quote_char        => '"',
    tag               => ['confluent', "confluent-${application}"],
    # lint:ignore:only_variable_string
    value             => "${value}"
    # lint:endignore
  }
}