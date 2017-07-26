require 'spec_helper'

describe 'confluent::zookeeper' do
  supported_osfamalies.each do |osfamily, osversions|
    osversions.each do |osversion|
      context "with osfamily => #{osfamily} and operatingsystemmajrelease => #{osversion}" do
        default_facts = {
            'osfamily' => osfamily,
            'operatingsystemmajrelease' => osversion
        }
        default_params = {
            'zookeeper_id' => '1',
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

        expected_heap = '-Xmx256M'

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
          end
        end


        it {is_expected.to contain_ini_subsetting('zookeeper_KAFKA_HEAP_OPTS').with({'path' => environment_file, 'value' => expected_heap})}
        it {is_expected.to contain_package('confluent-kafka-2.11')}
        it {is_expected.to contain_user('zookeeper')}
        it {is_expected.to contain_service('zookeeper').with({'ensure' => 'running', 'enable' => true})}
      end
    end
  end
end