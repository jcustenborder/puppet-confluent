require 'spec_helper'


%w(distributed standalone).each do |class_name|
  describe "confluent::kafka::connect::#{class_name}" do
    supported_osfamalies.each do |operating_system, default_facts|
      context "on #{operating_system}" do
        osfamily = default_facts['osfamily']
        default_params = {
            'bootstrap_servers' => %w(kafka-01:9093 kafka-02:9093 kafka-03:9093)
        }
        default_params['connector_configs'] = %w(/etc/kafka/connector1.properties /etc/kafka/connector2.properties) if class_name == 'standalone'
        let(:params) {default_params}
        let(:facts) {default_facts}

        user = "connect-#{class_name}"
        group = "connect-#{class_name}"
        service_name = "connect-#{class_name}"
        unit_file = "/usr/lib/systemd/system/#{service_name}.service"
        environment_file = nil

        config_path = "/etc/kafka/connect-#{class_name}.properties"
        logging_config_path="/etc/kafka/connect-#{class_name}.logging.properties"

        case osfamily
          when 'Debian'
            environment_file = "/etc/default/kafka-connect-#{class_name}"

          when 'RedHat'
            environment_file = "/etc/sysconfig/kafka-connect-#{class_name}"
        end

        expected_heap = '-Xmx512m'

        log_dirs = ["/var/log/kafka-connect-#{class_name}", "/app/var/log/kafka-connect-#{class_name}"]

        it {is_expected.to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
        context 'with restart_on_logging_change => false' do
          let(:params) {super().merge({'restart_on_logging_change' => false})}
          it {is_expected.not_to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
        end

        log_dirs.each do |log_dir|
          context "with param log_dir = '#{log_dir}'" do
            let(:params) {default_params.merge({'log_path' => log_dir})}

            it {is_expected.to contain_file(config_path).with_content(/bootstrap.servers=kafka-01:9093,kafka-02:9093,kafka-03:9093/)}
            it {is_expected.to contain_file(environment_file).with_content(/LOG_DIR="#{log_dir}"/)}
            it {is_expected.to contain_file(environment_file).with_content(/KAFKA_HEAP_OPTS="#{expected_heap}"/)}

            it {is_expected.to contain_file(log_dir).with({'owner' => "connect-#{class_name}", 'group' => "connect-#{class_name}", 'recurse' => true})}
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

            system_d_settings = {
                'Unit' => {
                    'Wants' => 'basic.target',
                    'After' => 'basic.target network-online.target',
                },
                'Service' => {
                    'Type' => 'simple',
                    'ExecStart' => "/usr/bin/connect-distributed #{config_path}",
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
            system_d_settings['Service']['ExecStart'] = "/usr/bin/connect-standalone /etc/kafka/connect-standalone.properties #{default_params['connector_configs'].join(' ')}" if class_name == 'standalone'
            system_d_settings.each do |section, section_values|
              it {is_expected.to contain_file(unit_file).with_content(/#{section}/)}

              section_values.each do |key, value|
                it {is_expected.to contain_file(unit_file).with_content(/#{key}=#{value}/)}
              end
            end
          end
        end
      end
    end
  end
end
