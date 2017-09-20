class { 'confluent::kafka::mirrormaker':
  instances => {
    'test-01' => {
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
    },
    'test-02' => {
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
    },
    'test-03' => {
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
    },
  }
}