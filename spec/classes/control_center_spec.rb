require 'spec_helper'

describe 'confluent::control::center' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      let(:facts) {default_facts}
      let(:params) {
        {
            'bootstrap_servers' => %w(kafka-01:9092 kafka-02:9092 kafka-03:9092),
            'connect_cluster' => %w(kafka-connect-01:8083 kafka-connect-02:8083 kafka-connect-03:8083),
            'zookeeper_connect' => %w(zookeeper-01:2181 zookeeper-02:2181 zookeeper-03:2181),
            'config' => {
                'confluent.controlcenter.streams.consumer.request.timeout.ms' => 180000
            }
        }
      }

      user='control-center'
      group='control-center'
      service_name = 'control-center'
      unit_file = "/usr/lib/systemd/system/#{service_name}.service"
      config_path = '/etc/confluent-control-center/control-center.properties'
      logging_config_path='/etc/confluent-control-center/control-center.logging.properties'

      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/control-center'
        when 'RedHat'
          environment_file = '/etc/sysconfig/control-center'
      end


      log_paths=%w(/var/log/control-center /logvol/var/log/control-center)
      log_paths.each do |log_path|
        context "with log_path => #{log_path}" do
          let(:params) {super().merge({'log_path' => log_path})}
          it {is_expected.to contain_file(log_path).with({'owner' => user, 'group' => group})}
          it {is_expected.to contain_file(environment_file).with_content(/LOG_DIR="#{log_path}"/)}
        end
      end

      data_paths=%w(/var/lib/control-center /logvol/var/lib/control-center)
      data_paths.each do |data_path|
        context "with data_path => #{data_path}" do
          let(:params) {super().merge({'data_path' => data_path})}
          it {is_expected.to contain_file(data_path).with({'owner' => user, 'group' => group})}
          it {is_expected.to contain_file(config_path).with_content(/confluent.controlcenter.data.dir=#{data_path}/)}
        end
      end


      it {is_expected.to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
      context 'with restart_on_logging_change => false' do
        let(:params) {super().merge({'restart_on_logging_change' => false})}
        it {is_expected.not_to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
      end
      context 'with restart_on_change => false' do
        let(:params) {super().merge({'restart_on_change' => false})}
        it {is_expected.not_to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
      end

      settings = {
          'bootstrap.servers' => 'kafka-01:9092,kafka-02:9092,kafka-03:9092',
          'confluent.controlcenter.connect.cluster' => 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083',
          'confluent.controlcenter.id' => '1',
          'confluent.controlcenter.streams.consumer.request.timeout.ms' => '180000',
          'zookeeper.connect' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'
      }

      settings.each do |key, value|
        it {is_expected.to contain_file(config_path).with_content(/#{key}=#{value}/)}
      end

      expected_heap = '-Xmx3096m'

      it {is_expected.to contain_yumrepo('Confluent').with({'ensure' => 'present'})} if osfamily == 'RedHat'
      it {is_expected.to contain_yumrepo('Confluent.dist').with({'ensure' => 'present'})} if osfamily == 'RedHat'

      it {is_expected.to contain_package('confluent-control-center')}
      it {is_expected.to contain_user(user)}
      it {is_expected.to contain_service(service_name).with({'ensure' => 'running', 'enable' => true})}
      it {is_expected.to contain_file(environment_file).with_content(/CONTROL_CENTER_HEAP_OPTS="#{expected_heap}"/)}

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
              'ExecStart' => "/usr/bin/control-center-start #{config_path}",
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
        it {is_expected.to contain_file(unit_file).with_owner('root').with_group('root').with_content(/#{section}/)}

        section_values.each do |key, value|
          it {is_expected.to contain_file(unit_file).with_content(/#{key}=#{value}/)}
        end
      end
    end
  end
end
