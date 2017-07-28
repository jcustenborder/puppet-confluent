require 'spec_helper'

describe 'confluent::kafka::rest' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      default_params = {
          'bootstrap_servers' =>  %w(kafka-01:9093 kafka-02:9093 kafka-03:9093),
          'zookeeper_connect' => %w(zookeeper-01:2181 zookeeper-02:2181 zookeeper-03:2181)
      }

      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/kafka-rest'
        when 'RedHat'
          environment_file = '/etc/sysconfig/kafka-rest'
      end

      let(:facts) {default_facts}
      let(:params) {default_params}

      log_paths = %w(/var/log/kafka-rest /logs/var/lib/kafka-rest)
      log_paths.each do |log_path|
        context "with log_path => #{log_path}" do
          let(:params) {default_params.merge({'log_path' => log_path})}
          it {is_expected.to contain_file(log_path).with({'owner' => 'kafka-rest', 'group' => 'kafka-rest'})}
          it {is_expected.to contain_ini_subsetting("kafka-rest_LOG_DIR").with({'value' => log_path})}
        end
      end

      expected_heap = '-Xmx512m'

      it {is_expected.to contain_ini_subsetting('kafka-rest_KAFKAREST_HEAP_OPTS').with({'path' => environment_file, 'value' => expected_heap})}
      it {is_expected.to contain_ini_setting('kafka-rest_zookeeper.connect').with({'path' => '/etc/kafka-rest/kafka-rest.properties', 'value' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'})}
      it {is_expected.to contain_ini_setting('kafka-rest_bootstrap.servers').with({'path' => '/etc/kafka-rest/kafka-rest.properties', 'value' => 'kafka-01:9093,kafka-02:9093,kafka-03:9093'})}
      it {is_expected.to contain_package('confluent-kafka-rest')}
      it {is_expected.to contain_user('kafka-rest')}
      it {is_expected.to contain_service('kafka-rest').with({'ensure' => 'running', 'enable' => true})}

      service_name = 'kafka-rest'
      system_d_settings = {
          "#{service_name}/Service/Type" => 'simple',
          "#{service_name}/Unit/Wants" => 'basic.target',
          "#{service_name}/Unit/After" => 'basic.target network.target',
          "#{service_name}/Service/User" => 'kafka-rest',
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