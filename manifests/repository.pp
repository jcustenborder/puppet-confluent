# Creates the repositories for installation.
#
#
class confluent::repository {
  case $::osfamily {
    'RedHat': {
      include ::confluent::repository::redhat
    }
    'Debian': {
      include ::confluent::repository::debian
    }
    default: {
      fail("${::osfamily} is not supported.")
    }
  }
}