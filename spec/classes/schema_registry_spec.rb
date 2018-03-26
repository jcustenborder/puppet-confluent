require 'spec_helper'

describe 'confluent::schema::registry' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      default_params = {
          'kafkastore_connection_url' => %w(zookeeper-01:2181 zookeeper-02:2181 zookeeper-03:2181)
      }

      user = 'schema-registry'
      group = 'schema-registry'
      service_name = 'schema-registry'
      unit_file = "/usr/lib/systemd/system/#{service_name}.service"
      environment_file = nil
      config_path='/etc/schema-registry/schema-registry.properties'
      logging_config_path='/etc/schema-registry/schema-registry.logging.properties'

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
          it {is_expected.to contain_file(log_path).with({'owner' => user, 'group' => group})}
          it {is_expected.to contain_file(environment_file).with_content(/LOG_DIR="#{log_path}"/)}
        end
      end

      expected_heap = '-Xmx512m'

      it {is_expected.to contain_file(environment_file).with_content(/SCHEMA_REGISTRY_HEAP_OPTS="#{expected_heap}"/)}
      it {is_expected.to contain_file(config_path).with_content(/kafkastore.connection.url=zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181/)}
      it {is_expected.to contain_package('confluent-schema-registry')}
      it {is_expected.to contain_user(user)}

      it {is_expected.to contain_file(unit_file).that_notifies('Exec[kafka-systemctl-daemon-reload]')}
      context 'with restart_on_change => false' do
        let(:params) {super().merge({'restart_on_change' => false})}
        it {is_expected.to contain_file(unit_file)}
      end
      it {is_expected.to contain_service(service_name).with({'ensure' => 'running', 'enable' => true})}
      it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{config_path}]")}
      context 'with restart_on_change => false' do
        let(:params) {super().merge({'restart_on_change' => false})}
        it {is_expected.not_to contain_service(service_name).that_subscribes_to("File[#{config_path}]")}
      end
      it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{unit_file}]")}
      context 'with restart_on_change => false' do
        let(:params) {super().merge({'restart_on_change' => false})}
        it {is_expected.not_to contain_service(service_name).that_subscribes_to("File[#{unit_file}]")}
      end
      it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{environment_file}]")}
      context 'with restart_on_change => false' do
        let(:params) {super().merge({'restart_on_change' => false})}
        it {is_expected.not_to contain_service(service_name).that_subscribes_to("File[#{environment_file}]")}
      end
      it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{logging_config_path}]")}
      context 'with restart_on_change => false' do
        let(:params) {super().merge({'restart_on_change' => false})}
        it {is_expected.not_to contain_service(service_name).that_subscribes_to("File[#{logging_config_path}]")}
      end

      it {is_expected.to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
      context 'with restart_on_logging_change => false' do
        let(:params) {super().merge({'restart_on_logging_change' => false})}
        it {is_expected.not_to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
      end

      system_d_settings = {
          'Unit' => {
              'Wants' => 'basic.target',
              'After' => 'basic.target network-online.target',
          },
          'Service' => {
              'Type' => 'simple',
              'ExecStart' => "/usr/bin/schema-registry-start #{config_path}",
              'User' => user,
              'TimeoutStopSec' => 300,
              'LimitNOFILE' => 128000,
              'KillMode' => 'process',
              'RestartSec' => 5,
          },
          'Install' => {
              'WantedBy' => 'multi-user.target'
          }
      }

      system_d_settings.each do |section, section_values|
        it {is_expected.to contain_file(unit_file).with_content(/#{section}/)}

        section_values.each do |key, value|
          it {is_expected.to contain_file(unit_file).with_content(/#{key}=#{value}/)}
        end
      end

    end
  end
end
