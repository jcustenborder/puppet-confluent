class confluent::kafka::connect (
  $connect_user = 'connect',
  $log4j_log_dir = '/var/log/kafka-connect'
) {
  include ::confluent::kafka

  user{ $connect_user:
    ensure => present,
    alias  => 'connect-user'
  } ->
  file{ $log4j_log_dir:
    ensure  => directory,
    owner   => $connect_user,
    group   => $connect_user,
    recurse => true
  }
}