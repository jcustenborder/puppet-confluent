require 'socket'

Puppet::Type.type(:kafka_topic).provide(:cli) do
  commands :kafka_topics  => '/bin/kafka-topics'
  commands :kafka_configs => '/bin/kafka-configs'

  mk_resource_methods

  def self.connection_args
    args = [ '--bootstrap-server', Socket.gethostbyname(Socket.gethostname).first + ":9092" ]
    args << [ '--command-config', '/etc/kafka/client.properties'] if File.file? '/etc/kafka/client.properties'
    args
  end

  def self.instances
    args = connection_args
    args << [ '--describe' ]

    configs = {}
    topic = nil
    config_regex = /^Dynamic configs for topic (.*) are:\s*$/i
    configs_output = kafka_configs(args << ['--entity-type', 'topics']).split("\n")
    configs_output.each do |line|
      if match = line.match(config_regex)
        topic = match.captures[0]
        configs[topic] = {}
        next
      end
      if match = line.match(/^\s+([^=;\s]+)=([^;\s]*)\s+.*$/)
        k, v = match.captures
        v = v.to_i if /^[-]?\d+$/.match(v)
        configs[topic][k] = v
      end
    end

    topics_regex = /^Topic:\s+([0-9a-zA-Z_.-]+)\s+PartitionCount:\s+([0-9]+)\s+ReplicationFactor:\s+([0-9]+)\s+Configs:\s+(.*)$/i
    topics_output = kafka_topics(args).split("\n")
    topics = topics_output.select do |line|
      line.match?(topics_regex)
    end
    topics.collect do |line|
      topic = {}
      name, parts, repl, _ = line.match(topics_regex).captures
      topic[:name] = name
      topic[:ensure] = :present
      topic[:partitions] = parts
      topic[:replication_factor] = repl
      topic[:config] = configs[name]
      new(topic)
    end
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.name])
        resource.provider = prov
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    fail("the 'partitions' parameter is mandatory when creating topics") if resource[:partitions].nil?
    args = self.class.connection_args
    args << [ '--partitions', resource[:partitions] ]
    args << [ '--replication-factor', resource[:replication_factor] ]
    args << [ '--create', '--topic', resource[:name] ]
    if ! resource[:config].nil?
      resource[:config].each do |k, v|
        args << ['--config', "#{k}=#{v}" ]
      end
    end
    begin
      kafka_topics(args)
    rescue Puppet::ExecutionFailure => e
      raise "Failed to create topic. Received error: #{e.inspect}"
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    args = self.class.connection_args
    args << [ '--delete', '--topic', resource[:name] ]
    begin
      kafka_topics(args)
    rescue Puppet::ExecutionFailure => e
      raise "Failed to delete topic. Received error: #{e.inspect}"
    end
    @property_hash.clear
  end

  def config=(value)
    current_config = @property_hash[:config]
    keys_to_delete = current_config.keys - resource[:config].keys
    args = self.class.connection_args
    args << [ '--alter', '--entity-type', 'topics', '--entity-name', resource[:name] ]
    args << [ '--add-config', resource[:config].map { |k, v| "#{k}=[#{v}]" }.join(',') ]
    if ! keys_to_delete.empty?
      args << [ '--delete-config', keys_to_delete.join(',') ]
    end
    begin
      kafka_configs(args)
    rescue Puppet::ExecutionFailure => e
      raise "Failed to describe topic. Received error: #{e.inspect}"
    end
  end

  #def partitions
  #  args = [ '--describe', '--topic', resource[:name] ]
  #  args += connection_args
  #  begin
  #    topics_output = kafka_topics(args)
  #  rescue Puppet::ExecutionFailure => e
  #    raise "Failed to list topic. Received error: #{e.inspect}"
  #  end
  #  topics_output.match(/PartitionCount:\s*([0-9]+)\s*$/i).captures
  #end

  def partitions=(value)
    warning("changing number of partitions after topic creation is not currently supported")
  end

  #def replication_factor
  #  args = [ '--describe', '--topic', resource[:name] ]
  #  args += connection_args
  #  begin
  #    topics_output = kafka_topics(args)
  #  rescue Puppet::ExecutionFailure => e
  #    raise "Failed to list topic. Received error: #{e.inspect}"
  #  end
  #  topics_output.match(/ReplicationFactor:\s*([0-9]+)\s*$/i).captures
  #end

  def replication_factor=(value)
    warning("changing the replication factor after topic creation is not currently supported")
  end
end
