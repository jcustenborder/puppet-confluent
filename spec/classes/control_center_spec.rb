require 'spec_helper'

describe 'confluent::control::center' do
  supported_osfamalies.each do |osfamily, osversions|
    osversions.each do |osversion|
      context "with osfamily => #{osfamily} and operatingsystemmajrelease => #{osversion}" do
        default_facts = {
            'osfamily' => osfamily,
            'operatingsystemmajrelease' => osversion
        }

        environment_file = nil

        case osfamily
          when 'Debian'
            environment_file = '/etc/default/control-center'
          when 'RedHat'
            environment_file = '/etc/sysconfig/control-center'
        end

        let(:facts) {default_facts}

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

        expected_heap = '-Xmx3g'

        it {is_expected.to contain_file('/var/log/control-center')}
        it {is_expected.to contain_package('confluent-control-center')}
        it {is_expected.to contain_user('control-center')}
        it {is_expected.to contain_service('control-center').with(
            {
                'ensure' => 'running',
                'enable' => true
            }
        )}

        it {is_expected.to contain_ini_subsetting('c3_CONTROL_CENTER_HEAP_OPTS').with(
            {
                'path' => environment_file,
                'value' => expected_heap
            }
        )}

        it {is_expected.to contain_ini_setting('c3_bootstrap.servers').with(
            {
                'path' => '/etc/confluent-control-center/control-center.properties',
                'value' => 'kafka-01:9092,kafka-02:9092,kafka-03:9092'
            }
        )}
      end
    end
  end
end