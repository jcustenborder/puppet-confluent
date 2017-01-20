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
  $ensure='present',
  $value=unset,
  $path,
  $application
) {
  $setting_name = "${application}_${name}"

  ini_setting{ $setting_name:
    ensure  => $ensure,
    path    => $path,
    section => '',
    setting => $name,
    tag     => 'kafka-setting',
    value   => $value
  }
}