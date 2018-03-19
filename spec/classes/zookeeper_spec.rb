require 'spec_helper'

describe 'confluent::zookeeper' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      let(:facts) {default_facts}
      let(:params) {
        {
            'zookeeper_id' => 1,
        }
      }

      user = 'zookeeper'
      group = 'zookeeper'
      config_path = '/etc/kafka/zookeeper.properties'
      logging_config_path='/etc/kafka/zookeeper.logging.properties'
      service_name = 'zookeeper'
      unit_file = "/usr/lib/systemd/system/#{service_name}.service"
      environment_file = nil


      case osfamily
        when 'Debian'
          environment_file = '/etc/default/zookeeper'
        when 'RedHat'
          environment_file = '/etc/sysconfig/zookeeper'
      end


      expected_heap = '-Xmx512m'

      data_paths = %w(/var/lib/zookeeper /data/var/lib/zookeeper)
      data_paths.each do |data_path|
        context "with data_path => #{data_path}" do
          let(:params) {super().merge({'data_path' => data_path})}
          it {is_expected.to contain_file(data_path).with({'owner' => user, 'group' => group})}
        end
      end

      log_paths = %w(/var/log/zookeeper /logs/var/lib/zookeeper)
      log_paths.each do |log_path|
        context "with log_path => #{log_path}" do
          let(:params) {super().merge({'log_path' => log_path})}
          it {is_expected.to contain_file(log_path).with({'owner' => user, 'group' => group})}
          it {is_expected.to contain_file(environment_file).with_content(/LOG_DIR="#{log_path}"/)}
        end
      end

      it {is_expected.to contain_file(environment_file).with_content(/KAFKA_HEAP_OPTS="#{expected_heap}"/)}
      it {is_expected.to contain_package('confluent-kafka-2.11')}
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
              'ExecStart' => "/usr/bin/zookeeper-server-start #{config_path}",
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
