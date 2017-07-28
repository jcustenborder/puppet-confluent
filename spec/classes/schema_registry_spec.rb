require 'spec_helper'

describe 'confluent::schema::registry' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      default_params = {
          'kafkastore_connection_url' => %w(zookeeper-01:2181 zookeeper-02:2181 zookeeper-03:2181)
      }

      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/schema-registry'
        when 'RedHat'
          environment_file = '/etc/sysconfig/schema-registry'
      end

      let(:facts) {default_facts}
      let(:params) {default_params}

      log_paths = %w(/var/log/schema-registry /logs/var/lib/schema-registry)
      log_paths.each do |log_path|
        context "with log_path => #{log_path}" do
          let(:params) {default_params.merge({'log_path' => log_path})}
          it {is_expected.to contain_file(log_path).with({'owner' => 'schema-registry', 'group' => 'schema-registry'})}
        end
      end

      expected_heap = '-Xmx256M'

      it {is_expected.to contain_ini_subsetting('schema-registry_SCHEMA_REGISTRY_HEAP_OPTS').with({'path' => environment_file, 'value' => expected_heap})}
      it {is_expected.to contain_ini_setting('schema-registry_kafkastore.connection.url').with({'path' => '/etc/schema-registry/schema-registry.properties', 'value' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'})}
      it {is_expected.to contain_package('confluent-schema-registry')}
      it {is_expected.to contain_user('schema-registry')}
      it {is_expected.to contain_service('schema-registry').with({'ensure' => 'running', 'enable' => true})}

      service_name = 'schema-registry'
      system_d_settings = {
          "#{service_name}/Service/Type" => 'simple',
          "#{service_name}/Unit/Wants" => 'basic.target',
          "#{service_name}/Unit/After" => 'basic.target network.target',
          "#{service_name}/Service/User" => 'schema-registry',
          "#{service_name}/Service/TimeoutStopSec" => '300',
          "#{service_name}/Service/LimitNOFILE" => '128000',
          "#{service_name}/Service/KillMode" => 'process',
          "#{service_name}/Service/RestartSec" => '5',
          "#{service_name}/Install/WantedBy" => 'multi-user.target',
      }

      system_d_settings.each do |ini_setting, value|
        it {is_expected.to contain_ini_setting(ini_setting).with({'value' => value})}
      end

    end
  end
end