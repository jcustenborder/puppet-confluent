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
  whitelist       => 'topic1|foo|.*bar'
}