class confluent::kafka::mirrormaker (
  $user = $::confluent::params::mirror_maker_user,

) inherits confluent::params {
  include ::confluent::kafka

  file { '/etc/kafka/mirrormaker':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    tag    => 'confluent'
  }
}