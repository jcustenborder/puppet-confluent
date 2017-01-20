## Introduction

This puppet module is used to install and configure the Confluent Platform. The documentation is available [here](http://jcustenborder.github.io/puppet-confluent/).

## Known issues

1. The only tested operating system is Centos 7. 
1. Yum repositories are not created.


### Usage

## Zookeeper

### Class installation

```puppet
class{'confluent::zookeeper':
  zookeeper_settings => {
    'myid' => {
      'value' => '1'
    }
  },
  java_settings => {
    'KAFKA_HEAP_OPTS' => {
      'value' => '-Xmx4000M'
    }
  }
}
```

### Hiera Installation

```puppet
include ::confluent::zookeeper
```

```yaml
confluent::zookeeper::zookeeper_settings:
  myid:
    value: '1'
  server.1:
    value: 'zookeeper-01.example.com:2888:3888'
  server.2:
    value: 'zookeeper-02.example.com:2888:3888'
  server.3:
    value: 'zookeeper-03.example.com:2888:3888'
confluent::zookeeper::java_settings:
  KAFKA_HEAP_OPTS:
    value: '-Xmx4000M'
```

## Kafka Broker

### Class installation

```puppet
class{'confluent::kafka::broker':
  kafka_settings => {
    'broker.id' => {
      'value' => '1'
    },
    'zookeeper.connect' => {
      'value' => 'zookeeper-01.custenborder.com:2181,zookeeper-02.custenborder.com:2181,zookeeper-03.:2181'
    },
  },
  java_settings => {
    'KAFKA_HEAP_OPTS' => {
      'value' => '-Xmx4000M'
    }
  }
}
```

### Heira installation

```puppet
include ::confluent::kafka::broker
```

```yaml
confluent::kafka::broker::kafka_settings:
  zookeeper.connect:
    value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
  broker.id:
    value: 0
  log.dirs:
    value: /var/lib/kafka
  advertised.listeners:
    value: "PLAINTEXT://%{::fqdn}:9092"
  delete.topic.enable:
    value: true
  auto.create.topics.enable:
    value: false
confluent::kafka::broker::java_settings:
  KAFKA_HEAP_OPTS:
    value: -Xmx1024M
```

## Kafka Connect

### Distributed

#### Class Installation

```puppet
class{'confluent::kafka::connect::distributed':
  connect_settings => {
    'bootstrap.servers' => {
      'value' => 'broker-01:9092,broker-02:9092,broker-03:9092'
    },
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
  java_settings => {
    'KAFKA_HEAP_OPTS' => {
      'value' => '-Xmx4000M'
    }
  }
}
```

#### Heira installation

```puppet
include ::confluent::kafka::connect::distributed
```

```yaml
confluent::kafka::connect::distributed::connect_settings:
  'bootstrap.servers':
    value: 'broker-01:9092,broker-02:9092,broker-03:9092'
  'key.converter':
    value: 'io.confluent.connect.avro.AvroConverter'
  'value.converter':
    value: 'io.confluent.connect.avro.AvroConverter'
  'key.converter.schema.registry.url':
    value: 'http://schema-registry-01.example.com:8081'
  'value.converter.schema.registry.url':
    value: 'http://schema-registry-01.example.com:8081'
confluent::kafka::connect::distributed::connect_settings:java_settings:
  KAFKA_HEAP_OPTS:
    value: '-Xmx4000M'
```

### Standalone

#### Class Installation

```puppet
class{'confluent::kafka::connect::standalone':
  connect_settings => {
    'bootstrap.servers' => {
      'value' => 'broker-01:9092,broker-02:9092,broker-03:9092'
    },
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
  java_settings => {
    'KAFKA_HEAP_OPTS' => {
      'value' => '-Xmx4000M'
    }
  }
}
```

#### Heira installation

```puppet
include ::confluent::kafka::connect::standalone
```

```yaml
confluent::kafka::connect::standalone::connect_settings:
  'bootstrap.servers':
    value: 'broker-01:9092,broker-02:9092,broker-03:9092'
  'key.converter':
    value: 'io.confluent.connect.avro.AvroConverter'
  'value.converter':
    value: 'io.confluent.connect.avro.AvroConverter'
  'key.converter.schema.registry.url':
    value: 'http://schema-registry-01.example.com:8081'
  'value.converter.schema.registry.url':
    value: 'http://schema-registry-01.example.com:8081'
confluent::kafka::connect::standalone::connect_settings:java_settings:
  KAFKA_HEAP_OPTS:
    value: '-Xmx4000M'
```

## Schema Registry

### Class installation
```puppet
class {'confluent::schema::registry':
  schemaregistry_settings => {
    'kafkastore.connection.url' => {
      'value' => 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
    },
  },
  java_settings => {
    'SCHEMA_REGISTRY_HEAP_OPTS' => {
      'value' => '-Xmx1024M'
    }
  }
}
```

### Hiera installation

```puppet
include ::confluent::schema::registry
```

```yaml
confluent::schema::registry::schemaregistry_settings:
  kafkastore.connection.url:
    value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
confluent::schema::registry::java_settings:
  SCHEMA_REGISTRY_HEAP_OPTS:
    value: -Xmx1024M
```

## Confluent Control Center

### Class installation

```puppet
class {'confluent::control::center':
  control_center_settings => {
    'zookeeper.connect' => {
      'value' => 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
    },
    'bootstrap.servers' => {
      'value' => 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
    },
    'confluent.controlcenter.connect.cluster' => {
      'value' => 'kafka-connect-01.example.com:8083,kafka-connect-02.example.com:8083,kafka-connect-03.example.com:8083'
    }
  },
  java_settings => {
    'CONTROL_CENTER_HEAP_OPTS' => {
      'value' => '-Xmx6g'
    }
  }
}
```

### Hiera installation

```puppet
include ::confluent::control::center
```

```yaml
confluent::control::center::control_center_settings:
  zookeeper.connect:
    value: 'zookeeper-01.example.com:2181,zookeeper-02.example.com:2181,zookeeper-03.example.com:2181'
  bootstrap.servers:
    value: 'kafka-01.example.com:9092,kafka-02.example.com:9092,kafka-03.example.com:9092'
  confluent.controlcenter.connect.cluster:
    value: 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083'
confluent::control::center::java_settings:
  CONTROL_CENTER_HEAP_OPTS:
    value: -Xmx6g
```

# Rebuild github pages

```bash
rake strings:gh_pages:update
```