require 'spec_helper'


%w(distributed standalone).each do |class_name|
  describe "confluent::kafka::connect::#{class_name}" do
    supported_osfamalies.each do |operating_system, default_facts|
      context "on #{operating_system}" do
        osfamily = default_facts['osfamily']
        default_params = {
            'bootstrap_servers' => %w(kafka-01:9093 kafka-02:9093 kafka-03:9093)
        }
        let(:params) {default_params}
        let(:facts) {default_facts}

        environment_file = nil

        case osfamily
          when 'Debian'
            environment_file = "/etc/default/kafka-connect-#{class_name}"
          when 'RedHat'
            environment_file = "/etc/sysconfig/kafka-connect-#{class_name}"
        end

        expected_heap = '-Xmx512m'

        log_dirs = ["/var/log/kafka-connect-#{class_name}", "/app/var/log/kafka-connect-#{class_name}"]

        log_dirs.each do |log_dir|
          context "with param log_dir = '#{log_dir}'" do
            let(:params) {default_params.merge({'log_path' => log_dir})}

            it {is_expected.to contain_ini_subsetting("connect-#{class_name}_LOG_DIR").with({'path' => environment_file, 'value' => log_dir})}
            it {is_expected.to contain_file(log_dir).with({'owner' => "connect-#{class_name}", 'group' => "connect-#{class_name}", 'recurse' => true})}
            it {is_expected.to contain_package('confluent-kafka-2.11')}
            it {is_expected.to contain_ini_setting("connect-#{class_name}_bootstrap.servers").with({'path' => "/etc/kafka/connect-#{class_name}.properties", 'value' => 'kafka-01:9093,kafka-02:9093,kafka-03:9093'})}
            it {is_expected.to contain_user("connect-#{class_name}")}
            it {is_expected.to contain_service("connect-#{class_name}").with({'ensure' => 'running', 'enable' => true})}
            it {is_expected.to contain_ini_subsetting("connect-#{class_name}_KAFKA_HEAP_OPTS").with({'path' => environment_file, 'value' => expected_heap})}

            service_name = "connect-#{class_name}"
            system_d_settings = {
                "#{service_name}/Service/Type" => 'simple',
                "#{service_name}/Unit/Wants" => 'basic.target',
                "#{service_name}/Unit/After" => 'basic.target network.target',
                "#{service_name}/Service/User" => "connect-#{class_name}",
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
    end
  end
end
# end