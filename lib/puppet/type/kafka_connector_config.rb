Puppet::Type.newtype(:kafka_connector_config) do
  @doc = %q{This type provides Puppet with the capabilities to manage Kafka connector configurations via the Connect API.

    Example:

      kafka_connector_config { 'local-file-sink':
        ensure => present,
        config => {
          'connector.class' => 'FileStreamSinkConnector',
          'tasks.max'       => 1,
          'file'            => 'test.sink.txt',
          'topics'          => 'connect-test',
        }
      }
  }

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the Kafka connector you want to manage.'
  end

  newproperty(:config) do
    desc 'A Hash containing the connector configurations to add.'
  end
end
