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

      default_params = {
          'broker_id' => '0'
      }

      context "with param data_path as array" do
        data_paths = %w(/data/kafka/disk01 /data/kafka/disk02 /data/kafka/disk03 /data/kafka/disk04)
        let(:params) {
          default_params.merge({'data_path' => data_paths})
        }
        it do
          is_expected.to contain_ini_setting('kafka_log.dirs').with(
              {
                  'value' => data_paths.join(',')
              }
          )
        end

        data_paths.each do |data_path|
          it do
            is_expected.to contain_file(data_path).with(
                {
                    'owner' => 'kafka',
                    'group' => 'kafka',
                    'recurse' => true
                }
            )
          end
        end
      end

      %w(/var/lib/kafka /datavol/var/lib/kafka).each do |data_path|
        context "with param data_path = '#{data_path}'" do
          let(:params) {
            default_params.merge({'data_path' => data_path})
          }
          it do
            is_expected.to contain_ini_setting('kafka_log.dirs').with(
                {
                    'value' => data_path
                }
            )
            is_expected.to contain_file(data_path).with(
                {
                    'owner' => 'kafka',
                    'group' => 'kafka',
                    'recurse' => true
                }
            )
          end
        end
      end

      %w(/var/log/kafka /logvol/var/log/kafka).each do |log_dir|
        context "with param log_dir = '#{log_dir}'" do
          let(:params) {
            default_params.merge({'log_path' => log_dir})
          }
          it do
            is_expected.to contain_ini_subsetting('kafka_LOG_DIR').with(
                {
                    'path' => environment_file,
                    'value' => log_dir
                }
            )
            is_expected.to contain_file(log_dir).with(
                {
                    'owner' => 'kafka',
                    'group' => 'kafka',
                    'recurse' => true
                }
            )
          end
        end
      end

      let(:params) {
        default_params
      }

      it do
        expected_heap = '-Xmx256M'

        is_expected.to contain_ini_subsetting('kafka_KAFKA_HEAP_OPTS').with(
            {
                'path' => environment_file,
                'value' => expected_heap
            }
        )

        is_expected.to contain_ini_setting('kafka_broker.id').with(
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

        is_expected.to contain_file('/var/lib/kafka')
      end

      service_name = 'kafka'
      system_d_settings = {
          "#{service_name}/Service/Type" => 'simple',
          "#{service_name}/Unit/Wants" => 'basic.target',
          "#{service_name}/Unit/After" => 'basic.target network.target',
          "#{service_name}/Service/User" => 'kafka',
          "#{service_name}/Service/TimeoutStopSec" => '300',
          "#{service_name}/Service/LimitNOFILE" => '128000',
          "#{service_name}/Service/KillMode" => 'process',
          "#{service_name}/Service/RestartSec" => '5',
          "#{service_name}/Install/WantedBy" => 'multi-user.target',
      }

      system_d_settings.each do |ini_setting, value|
        it do
          is_expected.to contain_ini_setting(ini_setting).with(
              {
                  'value' => value
              }
          )
        end
      end
    end
  end
end