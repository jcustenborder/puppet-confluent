# Class is used to install the core Kafka packages.
#
# @example Installing the Kafka packages.
#   include ::confluent::kafka
#
#
# @param package_ensure Ensure to be passed to the package installation.
# @param package_name Name of the package to install. This rarely needs to be changed unless you need to install a different version of Scala.
class confluent::kafka (
  String $package_ensure = 'installed',
  String $package_name   = $confluent::params::kafka_package_name
) inherits confluent::params {
  include ::confluent

  package { $package_name:
    ensure => $package_ensure,
    tag    => '__confluent__',
  }
}
