require 'spec_helper'

describe 'confluent::zookeeper' do


  %w(RedHat Debian).each do |osfamily|
    context "with osfamily => #{osfamily}" do
      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/zookeeper'
        when 'RedHat'
          environment_file = '/etc/sysconfig/zookeeper'
      end

      let(:facts) {
        {
            'osfamily' => osfamily
        }
      }

      let(:params) {
        {
            'zookeeper_id' => '1',
        }
      }

      it do
        expected_heap = '-Xmx256M'

        is_expected.to contain_ini_subsetting('zookeeper_KAFKA_HEAP_OPTS').with(
            {
                'path' => environment_file,
                'value' => expected_heap
            }
        )

        is_expected.to contain_package('confluent-kafka-2.11')
        is_expected.to contain_user('zookeeper')
        is_expected.to contain_service('zookeeper').with(
            {
                'ensure' => 'running',
                'enable' => true
            }
        )
        is_expected.to contain_file('/var/log/zookeeper')
        is_expected.to contain_file('/var/lib/zookeeper')
      end
    end
  end
end