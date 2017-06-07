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
  $path,
  $application,
  $ensure='present',
  $value=unset
) {
  $splitted = split($name, '/')
  $setting = $splitted[1]
  $setting_name = "${application}_${setting}"

  validate_absolute_path($path)

  ini_subsetting{ $setting_name:
    ensure            => $ensure,
    path              => $path,
    section           => '',
    setting           => $setting,
    subsetting        => '',
    key_val_separator => '=',
    quote_char        => '"',
    tag               => "${application}-setting",
    value             => $value
  }
}