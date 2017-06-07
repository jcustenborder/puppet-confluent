require 'spec_helper'

describe 'confluent::control::center' do
  %w(RedHat Debian).each do |osfamily|
    context "with osfamily => #{osfamily}" do
      environment_file = nil

      case osfamily
        when 'Debian'
          environment_file = '/etc/default/control-center'
        when 'RedHat'
          environment_file = '/etc/sysconfig/control-center'
      end

      let(:facts) {
        {
            'osfamily' => osfamily
        }
      }

      let(:params) {
        {
            'config' => {
                'bootstrap.servers' => {
                    'value' => 'kafka-01:9092,kafka-02:9092,kafka-03:9092'
                },
                'confluent.controlcenter.connect.cluster' => {
                    'value' => 'kafka-connect-01:8083,kafka-connect-02:8083,kafka-connect-03:8083'
                },
                'confluent.controlcenter.id' => {
                    'value' => '1'
                },
                'confluent.controlcenter.streams.consumer.request.timeout.ms' => {
                    'value' => '180000'
                },
                'zookeeper.connect' => {
                    'value' => 'zookeeper-01:2181,zookeeper-02:2181,zookeeper-03:2181'
                },
            }
        }
      }

      it do
        expected_heap = '-Xmx3g'

        is_expected.to contain_file('/var/log/control-center')
        is_expected.to contain_package('confluent-control-center')
        is_expected.to contain_user('control-center')
        is_expected.to contain_service('control-center').with(
            {
                'ensure' => 'running',
                'enable' => true
            }
        )

        is_expected.to contain_ini_subsetting('c3_CONTROL_CENTER_HEAP_OPTS').with(
            {
                'path' => environment_file,
                'value' => expected_heap
            }
        )

        is_expected.to contain_ini_setting('c3_c3/bootstrap.servers').with(
            {
                'path' => '/etc/confluent-control-center/control-center.properties',
                'value' => 'kafka-01:9092,kafka-02:9092,kafka-03:9092'
            }
        )


      end
    end
  end
end