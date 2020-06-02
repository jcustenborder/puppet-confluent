require 'digest'

Puppet::Type.type(:kafka_acl).provide(:cli) do
  commands :kafka_acls  => 'kafka-acls'

  mk_resource_methods

  def self.connection_args
    hostname = %x[hostname -f].chomp
    args = [ '--bootstrap-server', "#{hostname}:9092" ]
    args << [ '--command-config', '/etc/kafka/client.properties'] if File.file? '/etc/kafka/client.properties'
    args
  end

  def self.instances
    args = connection_args
    args << [ '--list' ]
    acls = []
    output = kafka_acls(args).split(/^Current ACLs for resource\s+/)
    output.reject! { |i| i.empty? || i !~ /^`ResourcePattern/ }
    output.each do |a|
      data = a.split("\n").map(&:strip)
      resource = data.shift
      type, name, pattern = resource.match(/^`ResourcePattern\(resourceType=(.*),\s+name=(.*),\s+patternType=(.*)\)`:$/i).captures
      type = type.downcase
      pattern = pattern.downcase
      data.each do |line|
        principal, host, op, perm = line.match(/^\(principal=(.*),\s+host=(.*),\s+operation=(.*),\s+permissionType=(.*)\)$/i).captures
        op = op.split('_').collect(&:capitalize).join
        hashed_name = Digest::SHA256.hexdigest format('%s/%s/%s/%s/%s/%s', type, name, principal, host, op, perm)
        acl = {
          :ensure                => :present,
          :name                  => hashed_name,
          :resource_pattern_type => pattern,
          :resource_type         => type,
          :resource_name         => name,
          :principal             => principal,
          :host                  => host,
          :operation             => op,
          :permission_type       => perm.downcase,
        }
        acls << new(acl)
      end 
    end
    acls
  end

  def self.prefetch(resources)
    acls = instances
    resources.each do |name, res|
      if (provider = acls.find { |acl| acl.resource_type == res[:resource_type] && acl.resource_name == res[:resource_name] && acl.principal == res[:principal] && acl.host == res[:host] && acl.operation == res[:operation] && acl.permission_type == res[:permission_type] })
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    args = self.class.connection_args
    args << [ '--add', '--force' ]
    if resource[:resource_type] != 'cluster'
      args << [ "--#{resource[:resource_type].tr('_', '-')}", "#{resource[:resource_name]}" ]
    else
      args << [ "--cluster" ]
    end
    args << [ "--#{resource[:permission_type]}-principal", "#{resource[:principal]}" ] if !resource[:principal].nil?
    args << [ "--#{resource[:permission_type]}-host", "#{resource[:host]}" ] if !resource[:host].nil?
    args << [ "--resource-pattern-type", "#{resource[:resource_pattern_type]}" ]
    args << [ "--operation", "#{resource[:operation]}" ]
    begin
      kafka_acls(args)
    rescue Puppet::ExecutionFailure => e
      raise "Failed to create ACL. Received error: #{e.inspect}"
    end
    @property_hash[:ensure] = :present
  end

  def destroy
    args = self.class.connection_args
    args << [ '--remove', '--force' ]
    if resource[:resource_type] != 'cluster'
      args << [ "--#{resource[:resource_type].tr('_', '-')}", "#{resource[:resource_name]}" ]
    else
      args << [ "--cluster" ]
    end
    args << [ "--#{resource[:permission_type]}-principal", "#{resource[:principal]}" ] if !resource[:principal].nil?
    args << [ "--#{resource[:permission_type]}-host", "#{resource[:host]}" ] if !resource[:host].nil?
    args << [ "--resource-pattern-type", "#{resource[:resource_pattern_type]}" ]
    args << [ "--operation", "#{resource[:operation]}" ]
    begin
      kafka_acls(args)
    rescue Puppet::ExecutionFailure => e
      raise "Failed to delete ACL. Received error: #{e.inspect}"
    end
    @property_hash.clear
  end
end
