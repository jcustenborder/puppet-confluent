require 'spec_helper'

describe 'confluent::kafka::broker' do


  %w(RedHat Debian).each do |osfamily|
    context "with osfamily => #{osfamily}" do
      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/kafka'
        when 'RedHat'
          environment_file = '/etc/sysconfig/kafka'
      end

      let(:facts) {
        {
            'osfamily' => osfamily
        }
      }

      let(:params) {
        {
            'broker_id' => '0'
        }
      }

      it do
        expected_heap = '-Xmx256M'

        is_expected.to contain_ini_subsetting('kafka_KAFKA_HEAP_OPTS').with(
            {
                'path' => environment_file,
                'value' => expected_heap
            }
        )

        is_expected.to contain_ini_setting('kafka_kafka/broker.id').with(
            {
                'path' => '/etc/kafka/server.properties',
                'value' => '0'
            }
        )
        is_expected.to contain_package('confluent-kafka-2.11')
        is_expected.to contain_user('kafka')
        is_expected.to contain_service('kafka').with(
            {
                'ensure' => 'running',
                'enable' => true
            }
        )
        is_expected.to contain_file('/var/log/kafka')
        is_expected.to contain_file('/var/lib/kafka')
      end
    end
  end
end