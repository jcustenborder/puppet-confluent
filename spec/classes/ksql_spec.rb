require 'spec_helper'

describe 'confluent::ksql' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']

      user = 'ksql'
      group = 'ksql'
      config_path = '/etc/ksql/ksql-server.properties'
      logging_config_path='/etc/ksql/ksql-server.logging.properties'
      service_name = 'ksql'
      unit_file = "/usr/lib/systemd/system/#{service_name}.service"
      environment_file = nil

      let(:facts) {default_facts}
      let(:params) {
        {
            'bootstrap_servers' => 'localhost',
            'service_name' => service_name
        }
      }

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/ksql'
        when 'RedHat'
          environment_file = '/etc/sysconfig/ksql'
      end

      %w(/var/log/ksql /logvol/var/log/ksql).each do |log_dir|
        context "with param log_dir = '#{log_dir}'" do
          let(:params) {super().merge({'log_path' => log_dir})}
          it {is_expected.to contain_file(environment_file).with_content(/LOG_DIR="#{log_dir}"/)}
          it {is_expected.to contain_file(log_dir).with(
              {
                  'owner' => user,
                  'group' => group,
                  'recurse' => true
              }
          )}
        end
      end

      expected_heap = '-Xmx512m'

      it {is_expected.to contain_file(environment_file).with_content(/KSQL_HEAP_OPTS="#{expected_heap}"/)}
      it {is_expected.to contain_package('confluent-ksql')}
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
              'ExecStart' => "/usr/bin/ksql-server-start #{config_path}",
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
