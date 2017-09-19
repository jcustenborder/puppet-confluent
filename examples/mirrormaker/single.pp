confluent::kafka::mirrormaker::instance{'testing':
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
  whitelist => '^productname-v1-(?!.*-unknown).*|^logs-pro|^bons-.*-test|^productname-v2-(realtime|longterm|logs|ets|metrics|mts)-.*-.*'
}