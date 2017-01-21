class confluent::params {
  $connect_distributed_user = 'connect-distributed'
  $connect_distributed_service = 'connect-distributed'
  $connect_distributed_manage_service = true
  $connect_distributed_service_ensure = 'running'
  $connect_distributed_service_enable = true
  $connect_distributed_file_limit = 65535
  $connect_distributed_properties_path = '/etc/kafka/connect-distributed.properties'
  $connect_distributed_log_path = '/var/log/kafka-connect-distributed'

  $connect_standalone_user = 'connect-standalone'
  $connect_standalone_service = 'connect-standalone'
  $connect_standalone_manage_service = true
  $connect_standalone_service_ensure = 'running'
  $connect_standalone_service_enable = true
  $connect_standalone_file_limit = 65535
  $connect_standalone_properties_path = '/etc/kafka/connect-standalone.properties'
  $connect_standalone_log_path = '/var/log/kafka-connect-standalone'



  case $::osfamily {
    'RedHat': {
      $connect_distributed_environment_file = '/etc/sysconfig/kafka-connect-distributed'
      $connect_standalone_environment_file = '/etc/sysconfig/kafka-connect-standalone'
    }
    'Debian': {
      $connect_distributed_environment_file = '/etc/default/kafka-connect-distributed'
      $connect_standalone_environment_file = '/etc/default/kafka-connect-standalone'
    }
    default: {
      fail("$osfamily is not currently supported.")
    }
  }


}