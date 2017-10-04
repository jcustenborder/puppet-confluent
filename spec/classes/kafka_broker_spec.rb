require 'spec_helper'

describe 'confluent::kafka::broker' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      default_params = {
          'broker_id' => 0
      }

      environment_file = nil


      case osfamily
        when 'Debian'
          environment_file = '/etc/default/kafka'
        when 'RedHat'
          environment_file = '/etc/sysconfig/kafka'
      end

      let(:facts) {default_facts}


      context "with param data_path as array" do
        data_paths = %w(/data/kafka/disk01 /data/kafka/disk02 /data/kafka/disk03 /data/kafka/disk04)
        let(:params) {
          default_params.merge({'data_path' => data_paths})
        }
        it {is_expected.to contain_file('/etc/kafka/server.properties').with_content(/log.dirs=#{data_paths.join(',')}/)}

        data_paths.each do |data_path|
          it {
            is_expected.to contain_file(data_path).with(
                {
                    'owner' => 'kafka',
                    'group' => 'kafka',
                    'recurse' => true
                }
            )
          }
        end
      end

      %w(/var/lib/kafka /datavol/var/lib/kafka).each do |data_path|
        context "with param data_path = '#{data_path}'" do
          let(:params) {super().merge({'data_path' => data_path})}
          it {is_expected.to contain_file('/etc/kafka/server.properties').with_content(/log.dirs=#{data_path}/)}
          it {is_expected.to contain_file(data_path).with(
              {
                  'owner' => 'kafka',
                  'group' => 'kafka',
                  'recurse' => true
              }
          )}
        end
      end


      %w(/var/log/kafka /logvol/var/log/kafka).each do |log_dir|
        context "with param log_dir = '#{log_dir}'" do
          let(:params) {super().merge({'log_path' => log_dir})}
          it {is_expected.to contain_file(environment_file).with_content(/LOG_DIR="#{log_dir}"/)}
          it {is_expected.to contain_file(log_dir).with(
              {
                  'owner' => 'kafka',
                  'group' => 'kafka',
                  'recurse' => true
              }
          )}
        end
      end


      let(:params) {
        default_params
      }

      expected_heap = '-Xmx1024m'

      it {is_expected.to contain_file(environment_file).with_content(/KAFKA_HEAP_OPTS="#{expected_heap}"/)}
      it {is_expected.to contain_file('/etc/kafka/server.properties').with_content(/broker.id=0/)}
      it {is_expected.to contain_package('confluent-kafka-2.11')}
      it {is_expected.to contain_user('kafka')}
      it {is_expected.to contain_service('kafka').with({'ensure' => 'running', 'enable' => true})}

      it {is_expected.to contain_file('/var/lib/kafka')}

      service_name = 'kafka'
      unit_file = "/usr/lib/systemd/system/#{service_name}.service"
      system_d_settings = {
          'Service' => {
              'Type' =>'simple'
          },
          'Unit' => {
              'Wants' => 'basic.target',
              'After' => 'basic.target network-online.target',
          },
          'Service' => {
              'User' => 'kafka',
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
        it {is_expected.to contain_file(unit_file).with_content(/#{section}/)}

        section_values.each do |key, value|
          it {is_expected.to contain_file(unit_file).with_content(/#{key}=#{value}/)}
        end

        it {is_expected.to contain_file('/etc/kafka/server.properties').with_content(/broker.id=0/)}
      end
    end
  end
end
