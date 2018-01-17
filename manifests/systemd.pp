# Class is used to hold a resource to reload systemd due to a unit file change. This class is used internally and should
# not be referenced directly.
#
class confluent::systemd {
  exec { 'kafka-systemctl-daemon-reload':
    command     => 'systemctl daemon-reload',
    path        => [
      '/usr/bin'
    ],
    refreshonly => true
  } -> Service<| tag == '__confluent__' |>
}
