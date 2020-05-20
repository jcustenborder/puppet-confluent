Puppet::Type.newtype(:kafka_acl) do
  @doc = %q{This type provides Puppet with the capabilities to manage ACLs in a Kafka cluster.

    Example:

      kafka_acl { 'foo':
        ensure => 'present',
      }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Arbitrary name for kafka_acl resource. Must be unique.'
  end

  newproperty(:principal) do
    desc 'A String containing the principal the ACL will apply to. Defaults to "User:*".'
    defaultto 'User:*'
    validate do |value|
      unless value.is_a? String
        raise ArgumentError, 'principal should be an String'
      end
    end
  end

  newproperty(:host) do
    desc 'A String containing the host the ACL will apply to. Defaults to "*".'
    defaultto '*'
    validate do |value|
      unless value.is_a? String
        raise ArgumentError, 'host should be an String'
      end
    end
  end

  newproperty(:operation) do
    desc 'A String containing the operation the ACL will target. Defaults to "All".'
    defaultto "All"
    validate do |value|
      unless value.is_a? String and ['Read','Write','Create','Delete','Alter','Describe','ClusterAction',
                                     'AlterConfigs','DescribeConfigs','IdempotentWrite','All'].include? value
        raise ArgumentError, 'operation should be one of the folowing values: "Read","Write","Create","Delete","Alter","Describe","ClusterAction", "AlterConfigs","DescribeConfigs","IdempotentWrite",or "All".'
      end
    end
  end

  newproperty(:permission_type) do
    desc 'A String containing the permission type for the ACL.'
    validate do |value|
      unless value.is_a? String and ['allow','deny'].any? { |s| s.casecmp(value) == 0 }
        raise ArgumentError, 'permission_type should be either "allow" or "deny"'
      end
    end
    munge { |value| value.downcase }
  end

  newproperty(:resource_name) do
    desc 'A String identifying the Kafka resource name the ACL will apply to.'
    validate do |value|
      unless value.is_a? String
        raise ArgumentError, 'resource_name should be a String'
      end
    end
  end

  newproperty(:resource_type) do
    desc 'A String identifying the Kafka resource type the ACL will apply to.'
    validate do |value|
      unless value.is_a? String and ['topic', 'group', 'delegation_token', 'transactional_id', 'cluster'].any? { |s| s.casecmp(value) == 0 }
        raise ArgumentError, 'resource_pattern_type must be one of "topic", "group", "delegation_token", "transactional_id", or "cluster"'
      end
    end
    munge { |value| value.downcase }
  end

  newparam(:resource_pattern_type) do
    desc 'A String identifying the type of the resource pattern or pattern filter. Acceptible values are "literal", "prefix", "match", or "any". Defaults to "literal".'
    defaultto 'literal'
    validate do |value|
      unless value.is_a? String and ['literal', 'prefix', 'match', 'any'].any? { |s| s.casecmp(value) == 0 }
        raise ArgumentError, 'resource_pattern_type must be one of "literal", "prefix", "match", or "any"'
      end
    end
    munge { |value| value.downcase }
  end
end
