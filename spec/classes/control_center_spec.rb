require 'spec_helper'

describe 'confluent::control::center' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      default_params = {
          'bootstrap_servers' => %w(kafka-01:9092 kafka-02:9092 kafka-03:9092),
          'connect_cluster' => %w(kafka-connect-01:8083 kafka-connect-02:8083 kafka-connect-03:8083),
          'zookeeper_connect' => %w(zookeeper-01:2181 zookeeper-02:2181 zookeeper-03:2181),
          'config' => {
              'confluent.controlcenter.streams.consumer.request.timeout.ms' => {
                  'value' => '180000'
              },
          }
      }

      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/control-center'
        when 'RedHat'
          environment_file = '/etc/sysconfig/control-center'
      end

      let(:facts) {default_facts}
      let(:params) {default_params}

      log_paths=%w(/var/log/control-center /logvol/var/log/control-center)
      log_paths.each do |log_path|
        context "with log_path => #{log_path}" do
          let(:params) {default_params.merge({'log_path' => log_path})}
          it {is_expected.to contain_file(log_path).with({'owner' => 'control-center', 'group' => 'control-center'})}
          it {is_expected.to contain_ini_subsetting('c3/LOG_DIR').with({'path' => environment_file, 'value' => log_path}
          )}
        end
      end

      data_paths=%w(/var/lib/control-center /logvol/var/lib/control-center)
      data_paths.each do |data_path|
        context "with data_path => #{data_path}" do
          let(:params) {default_params.merge({'data_path' => data_path})}
          it {is_expected.to contain_file(data_path).with({'owner' => 'control-center', 'group' => 'control-center'})}
          it {is_expected.to contain_ini_setting("c3/confluent.controlcenter.data.dir").with(
              'path' => '/etc/confluent-control-center/control-center.properties',
              'value' => data_path
          )}
        end
      end

      settings = {
          'bootstrap.servers' => 'kafka-01:9092,kafka-02:9092,kafka-03:9092',
          'confluent.controlcenter.connect.cluster' => 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083',
          'confluent.controlcenter.id' => '1',
          'confluent.controlcenter.streams.consumer.request.timeout.ms' => '180000',
          'zookeeper.connect' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'
      }

      settings.each do |key, value|
        it {is_expected.to contain_ini_setting("c3/#{key}").with(
            'path' => '/etc/confluent-control-center/control-center.properties',
            'value' => value
        )}

      end


      expected_heap = '-Xmx3096m'

      it {is_expected.to contain_yumrepo('Confluent').with({'ensure' => 'present'})} if osfamily == 'RedHat'
      it {is_expected.to contain_yumrepo('Confluent.dist').with({'ensure' => 'present'})} if osfamily == 'RedHat'

      it {is_expected.to contain_package('confluent-control-center')}
      it {is_expected.to contain_user('control-center')}
      it {is_expected.to contain_service('control-center').with({'ensure' => 'running', 'enable' => true})}
      it {is_expected.to contain_ini_subsetting('c3/CONTROL_CENTER_HEAP_OPTS').with({'path' => environment_file, 'value' => expected_heap}
      )}
      service_name = 'control-center'
      system_d_settings = {
          "#{service_name}/Service/Type" => 'simple',
          "#{service_name}/Unit/Wants" => 'basic.target',
          "#{service_name}/Unit/After" => 'basic.target network.target',
          "#{service_name}/Service/User" => 'control-center',
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
