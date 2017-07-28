# Class is used to configure the repository for $::osfamily == 'RedHat'
#
#
class confluent::repository::redhat (
  $dist_repository_url = $::confluent::params::dist_repository_url,
  $repository_url      = $::confluent::params::repository_url,
  $gpgkey_url          = $::confluent::params::gpgkey_url
) inherits confluent::params {

  yumrepo { 'Confluent':
    ensure   => 'present',
    baseurl  => $repository_url,
    descr    => 'Confluent repository',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => $gpgkey_url,
  }
  yumrepo { 'Confluent.dist':
    ensure   => 'present',
    baseurl  => $dist_repository_url,
    descr    => 'Confluent repository (dist)',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => $gpgkey_url,
  }

  #Ensure that repositories are configured before packages are installed.
  Yumrepo<| |> -> Package<| provider == 'yum' |>
}