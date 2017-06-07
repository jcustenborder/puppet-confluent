# Class is used to install the core Kafka packages.
#
# @example Installing the Kafka packages.
#   include ::confluent::kafka
#
#
# @param package_ensure Ensure to be passed to the package installation.
# @param package_name Name of the package to install. This rarely needs
# to be changed unless you need to install a different version of Scala.
class confluent::kafka(
  $package_ensure='installed',
  $package_name='confluent-kafka-2.11'
)  {

  package{ $package_name:
    ensure => $package_ensure,
    alias  => 'kafka'
  } -> Ini_setting <| tag == 'kafka-setting' |>
}