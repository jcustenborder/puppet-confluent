# Class is used to configure the repository for $::osfamily == 'RedHat'
#
#
class confluent::repository::redhat (
  Variant[Stdlib::Httpsurl, Stdlib::Httpurl] $dist_repository_url = $::confluent::params::dist_repository_url,
  Variant[Stdlib::Httpsurl, Stdlib::Httpurl] $repository_url      = $::confluent::params::repository_url,
  Variant[Stdlib::Httpsurl, Stdlib::Httpurl] $gpgkey_url          = $::confluent::params::gpgkey_url
) inherits confluent::params {

  yumrepo { 'Confluent':
    ensure   => 'present',
    baseurl  => $repository_url,
    descr    => 'Confluent repository',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => $gpgkey_url,
    tag      => '__confluent__'
  }
  yumrepo { 'Confluent.dist':
    ensure   => 'present',
    baseurl  => $dist_repository_url,
    descr    => 'Confluent repository (dist)',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => $gpgkey_url,
    tag      => '__confluent__'
  }

  Yumrepo<| tag == '__confluent__' |> -> Package<| tag == '__confluent__' |>
}
