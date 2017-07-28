## Introduction

This puppet module is used to install and configure the Confluent Platform. The documentation is available [here](http://jcustenborder.github.io/puppet-confluent/).

## Note on versioning

Puppet only allows version numbers in `<major>.<minor>.<version>` format. Due to this limitation the versioning schema matches 
the major and minor versions of the Confluent Platform. Meaning 3.2.1234 of the puppet module is for 3.2.x of the Confluent platform.

### Usage

## Zookeeper

### Class installation

```puppet
class{'confluent::zookeeper':
  zookeeper_id => '1',
  heap_size => '4000M'
}
```

### Hiera Installation

```puppet
include ::confluent::zookeeper
```

```yaml
confluent::zookeeper::zookeeper_id: '1'
confluent::zookeeper::config:
  server.1:
    value: 'zookeeper-01.example.com:2888:3888'
  server.2:
    value: 'zookeeper-02.example.com:2888:3888'
  server.3:
    value: 'zookeeper-03.example.com:2888:3888'
confluent::zookeeper::heap_size: '4000M'
```

## Kafka Broker

### Class installation

```puppet
class{'confluent::kafka::broker':
  broker_id => '1',
  zookeeper_connect => [
    'zookeeper-01:2181',
    'zookeeper-02:2181',
    'zookeeper-03:2181'
  ],
  heap_size => '4000M'
}
```

### Heira installation

```puppet
include ::confluent::kafka::broker
```

```yaml
confluent::kafka::broker::broker_id: '1'
confluent::kafka::broker::heap_size: '4000M'
confluent::kafka::broker::zookeeper_connect:
  - 'zookeeper-01:2181',
  - 'zookeeper-02:2181',
  - 'zookeeper-03:2181'
confluent::kafka::broker::data_path: '/var/lib/kafka'
```

## Kafka Connect

### Distributed

#### Class Installation

```puppet
class{'confluent::kafka::connect::distributed':
  heap_size => '4000M',
  bootstrap_servers => [
    'broker-01:9092',
    'broker-02:9092',
    'broker-03:9092'
  ],
  config => {
    'key.converter' => {
      'value' => 'io.confluent.connect.avro.AvroConverter'
    },
    'value.converter' => {
      'value' => 'io.confluent.connect.avro.AvroConverter'
    },
    'key.converter.schema.registry.url' => {
      'value' => 'http://schema-registry-01:8081'
    },
    'value.converter.schema.registry.url' => {
      'value' => 'http://schema-registry-01:8081'
    },
  },
}
```

#### Heira installation

```puppet
include ::confluent::kafka::connect::distributed
```

```yaml
 confluent::kafka::connect::distributed::heap_size: '4000M'
 confluent::kafka::connect::distributed::bootstrap_servers:
  - broker-01:9092
  - broker-02:9092
  - broker-03:9092
 confluent::kafka::connect::distributed::config:
   'key.converter':
     value: 'io.confluent.connect.avro.AvroConverter'
   'value.converter':
     value: 'io.confluent.connect.avro.AvroConverter'
   'key.converter.schema.registry.url':
     value: 'http://schema-registry-01.example.com:8081'
   'value.converter.schema.registry.url':
     value: 'http://schema-registry-01.example.com:8081'
```

### Standalone

#### Class Installation

```puppet
class{'confluent::kafka::connect::standalone':
  heap_size => '4000M',
  bootstrap_servers => [
    'broker-01:9092',
    'broker-02:9092',
    'broker-03:9092'
  ],
  config => {
    'key.converter' => {
      'value' => 'io.confluent.connect.avro.AvroConverter'
    },
    'value.converter' => {
      'value' => 'io.confluent.connect.avro.AvroConverter'
    },
    'key.converter.schema.registry.url' => {
      'value' => 'http://schema-registry-01:8081'
    },
    'value.converter.schema.registry.url' => {
      'value' => 'http://schema-registry-01:8081'
    },
  },
}
```

#### Heira installation

```puppet
include ::confluent::kafka::connect::standalone
```

```yaml
 confluent::kafka::connect::standalone::heap_size: '4000M'
 confluent::kafka::connect::standalone::bootstrap_servers:
  - broker-01:9092
  - broker-02:9092
  - broker-03:9092
 confluent::kafka::connect::standalone::config:
   'key.converter':
     value: 'io.confluent.connect.avro.AvroConverter'
   'value.converter':
     value: 'io.confluent.connect.avro.AvroConverter'
   'key.converter.schema.registry.url':
     value: 'http://schema-registry-01.example.com:8081'
   'value.converter.schema.registry.url':
     value: 'http://schema-registry-01.example.com:8081'
```

## Schema Registry

### Class installation
```puppet
class {'confluent::schema::registry':
  heap_size => '1024M',
  kafkastore_connection_url => [
      'zookeeper-01:2181',
      'zookeeper-02:2181',
      'zookeeper-03:2181'
  ]
}
```

### Hiera installation

```puppet
include ::confluent::schema::registry
```

```yaml
confluent::schema::registry::heap_size: '1024M'
confluent::schema::registry::kafkastore_connection_url:
  - 'zookeeper-01:2181'
  - 'zookeeper-02:2181'
  - 'zookeeper-03:2181'
```

## Confluent Control Center

### Class installation

```puppet
class {'confluent::control::center':
  heap_size => '6g',
  zookeeper_connect => [
    'zookeeper-01:2181',
    'zookeeper-02:2181',
    'zookeeper-03:2181'
  ],
  bootstrap_servers => [
    'broker-01:9092',
    'broker-02:9092',
    'broker-03:9092'
  ],
  connect_cluster => [
    'kafka-connect-01.example.com:8083',
    'kafka-connect-02.example.com:8083',
    'kafka-connect-03.example.com:8083'
  ]
}
```

### Hiera installation

```puppet
include ::confluent::control::center
```

```yaml
confluent::control::center::heap_size: '6g'
confluent::control::center::zookeeper_connect: 
  - 'zookeeper-01:2181'
  - 'zookeeper-02:2181'
  - 'zookeeper-03:2181'
confluent::control::center::bootstrap_servers: 
  - 'broker-01:9092'
  - 'broker-02:9092'
  - 'broker-03:9092'
confluent::control::center::connect_cluster: 
  - 'kafka-connect-01.example.com:8083'
  - 'kafka-connect-02.example.com:8083'
  - 'kafka-connect-03.example.com:8083'
```

# Run tests

```bash
rake spec
```

# Rebuild github pages

```bash
rake strings:gh_pages:update
```