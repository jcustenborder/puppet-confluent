require 'pathname'

Puppet::Type.newtype(:kafka_topic) do
  @doc = %q{This type provides Puppet with the capabilities to manage topics in a Kafka cluster.

    Example:

      kafka_topic { 'foo':
        ensure => 'present',
      }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the Kafka topic you want to manage.'
  end

  newproperty(:config) do
    desc 'A Hash of key/value pairs of topic configs to add.'
  end

  newproperty(:partitions) do
    desc 'The number of partitions for the topic (WARNING: If partitions are increased for a topic that has a key, the partition logic or ordering of the messages will be affected).'
    validate do |value|
      unless value.is_a? Integer
        raise ArgumentError, "partitions should be an Integer"
      end
      unless value > 0
        raise ArgumentError, "the number of partitions should be greater than 0"
      end
    end
  end

  newproperty(:replication_factor) do
    desc 'The replication factor for each partition in the topic being created. If not supplied, defaults to the cluster default.'
    validate do |value|
      unless value.is_a? Integer
        raise ArgumentError, "replication_factor should be an Integer"
      end
    end
  end

  #newparam(:replica_assignment) do
  #  #  desc 'A list of manual partition-to-broker assignments for the topic being created or altered.'
  #    #end
end
