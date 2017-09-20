class { 'confluent::repository::redhat':
  repository_url      => 'http://packages.confluent.io/rpm/2.0',
  dist_repository_url => 'http://packages.confluent.io/rpm/2.0/7',
  gpgkey_url          => 'http://packages.confluent.io/archive.key',
}

class { 'confluent::kafka':
  package_name => 'confluent-kafka-2.10.5'
}

confluent::kafka::mirrormaker::instance { 'testing':
  consumer_config => {
    'bootstrap.servers' => {
      'value' => 'kafka-01.remote.net:9092'
    }
  },
  producer_config => {
    'bootstrap.servers' => {
      'value' => 'kafka-01.local.net:9092'
    }
  },
  whitelist       =>
    'topic1|foo|.*bar'
}