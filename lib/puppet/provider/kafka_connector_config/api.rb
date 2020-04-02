require 'openssl'
require 'net/http'
require 'json'
require 'yaml'
require 'uri'

Puppet::Type.type(:kafka_connector_config).provide(:api) do

  mk_resource_methods

  def self.load_config
    config = '/etc/puppetlabs/kafka_connector_config.yaml'
    begin
      YAML.load_file(config)
    rescue Exception => e
      raise Puppet::Error, "Failed to load kafka_connector_config provider config from #{config}. Received error: #{e.inspect}"
    end
  end

  def self.new_client
    config = load_config
    if ! config.key?('endpoint')
      raise Puppet::Error, "endpoint must be defined in the /etc/puppetlabs/kafka_connector_config.yaml configuration file"
    end
    uri              = URI.parse(config['endpoint'])
    http             = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl     = (uri.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? and !config['insecure']
    if http.use_ssl?
      if config.key?('ca_file')
        http.ca_file = config['ca_file']
      end
      if config.key?('cert_file') and config.key?('key_file')
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.key = OpenSSL::PKey::RSA.new(File.read(config['key_file']))
        http.cert = OpenSSL::X509::Certificate.new(File.read(config['cert_file']))
      end
    end
    http
  end

  def self.instances
    conn = new_client
    request = Net::HTTP::Get.new('/connectors')
    Puppet.debug("Retrieving connectors with GET request to #{conn.address}:#{conn.port}#{request.path}")
    response = conn.request(request)
    connectors = JSON.parse(response.body)
    connectors.collect do |connector|
      c = {}
      conn = new_client
      request = Net::HTTP::Get.new("/connectors/#{connector}/config")
      Puppet.debug("Retrieving config for #{connector} with GET request to #{conn.address}:#{conn.port}#{request.path}")
      response = conn.request(request)
      config = JSON.parse(response.body)
      config.delete('name')
      c[:name] = connector
      c[:ensure] = :present
      c[:config] = config
      new(c)
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
    conn = self.class.new_client
    request = Net::HTTP::Post.new('/connectors', 'Content-Type' => 'application/json')
    body = { 'name' => resource[:name], 'config' => resource[:config] }
    Puppet.debug("Sending POST request to #{conn.address}:#{conn.port}#{request.path} with data #{body}")
    request.body = body.to_json
    begin
      response = conn.request(request)
      response.value
      Puppet.debug("    Response was #{response.code}: #{response.body}")
    rescue Net::HTTPError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise Puppet::Error, "Failed to create connector config. Received error: #{e.inspect}"
    end
  end

  def destroy
    conn = self.class.new_client
    request = Net::HTTP::Delete.new("/connectors/#{resource[:name]}")
    Puppet.debug("Sending DELETE request to #{conn.address}:#{conn.port}#{request.path}")
    begin
      response = conn.request(request)
      response.value
      Puppet.debug("    Response was #{response.code}: #{response.body}")
    rescue Net::HTTPError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise Puppet::Error, "Failed to delete connector config. Received error: #{e.inspect}"
    end
    @property_hash.clear
  end

  def config=(value)
    conn = self.class.new_client
    request = Net::HTTP::Put.new("/connectors/#{@property_hash[:name]}/config", 'Content-Type' => 'application/json')
    Puppet.debug("Sending POST request to #{conn.address}:#{conn.port}#{request.path} with data #{resource[:config]}")
    request.body = resource[:config].to_json
    begin
      response = conn.request(request)
      response.value
      Puppet.debug("    Response was #{response.code}: #{response.body}")
    rescue Net::HTTPError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
       Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
      raise Puppet::Error, "Failed to create connector config. Received error: #{e.inspect}"
    end
  end
end
