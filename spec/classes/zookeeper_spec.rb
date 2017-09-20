require 'spec_helper'

describe 'confluent::zookeeper' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      default_params = {
          'zookeeper_id' => 1,
      }
      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/zookeeper'
        when 'RedHat'
          environment_file = '/etc/sysconfig/zookeeper'
      end

      let(:facts) {default_facts}
      let(:params) {default_params}

      expected_heap = '-Xmx512m'

      data_paths = %w(/var/lib/zookeeper /data/var/lib/zookeeper)
      data_paths.each do |data_path|
        context "with data_path => #{data_path}" do
          let(:params) {default_params.merge({'data_path' => data_path})}
          it {is_expected.to contain_file(data_path)}
        end
      end

      log_paths = %w(/var/log/zookeeper /logs/var/lib/zookeeper)
      log_paths.each do |log_path|
        context "with log_path => #{log_path}" do
          let(:params) {default_params.merge({'log_path' => log_path})}
          it {is_expected.to contain_file(log_path).with({'owner' => 'zookeeper', 'group' => 'zookeeper'})}
          it {is_expected.to contain_ini_subsetting('zookeeper/LOG_DIR').with({'path' => environment_file, 'value' => log_path})}
        end
      end


      it {is_expected.to contain_ini_subsetting('zookeeper/KAFKA_HEAP_OPTS').with({'path' => environment_file, 'value' => expected_heap})}
      it {is_expected.to contain_package('confluent-kafka-2.11')}
      it {is_expected.to contain_user('zookeeper')}
      it {is_expected.to contain_service('zookeeper').with({'ensure' => 'running', 'enable' => true})}

      service_name = 'zookeeper'
      system_d_settings = {
          "#{service_name}/Service/Type" => 'simple',
          "#{service_name}/Unit/Wants" => 'basic.target',
          "#{service_name}/Unit/After" => 'basic.target network-online.target',
          "#{service_name}/Service/User" => 'zookeeper',
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