class confluent (
  String $package_name       = $::confluent::params::package_name,
  Boolean $manage_repository = $::confluent::params::manage_repository,
  String $package_ensure     = 'installed',
) {
  Package<| tag == '__confluent__' |>
  -> User<| tag == '__confluent__' |>
  -> File<| tag == '__confluent__' |>
  -> Service<| tag == '__confluent__' |>

  if($manage_repository) {
    include ::confluent::repository
  }

  package { $package_name:
    ensure => $package_ensure,
    tag    => '__confluent__',
  }
}
