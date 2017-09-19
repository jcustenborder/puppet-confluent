require 'spec_helper'

describe 'confluent::kafka::mirrormaker::instance' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      title = 'testing'


      osfamily = default_facts['osfamily']
      let(:facts) {default_facts}
      let(:title) {title}
      let(:params) {
        {
            :client_id => 'instance-01',
            :consumer_config => {
                'group.id' => {
                    'value' => 'mirrormaker'
                },
                'bootstrap.servers' => {
                    'value' => 'kafka-01:9092'
                }
            },
            :producer_config => {
                'bootstrap.servers' => {
                    'value' => 'kafka-01:9092'
                }
            },
            :whitelist => '^productname-v1-(?!.*-unknown).*|^logs-pro|^bons-.*-test|^productname-v2-(realtime|longterm|logs|ets|metrics|mts)-.*-.*'
        }
      }


      it {is_expected.to contain_user('mirrormaker')}
      expected_classes = %w(confluent::kafka::mirrormaker confluent::kafka confluent)
      expected_classes.each do |expected_class|
        it {is_expected.to contain_class(expected_class)}
      end


      it {is_expected.to contain_file('/var/log/mirrormaker').with({'owner' => 'root', 'group' => 'root'})}
      it {is_expected.to contain_file("/var/log/mirrormaker/#{title}").with({'owner' => 'mirrormaker', 'group' => 'root'})}

      it {is_expected.to contain_file('/etc/kafka/mirrormaker').with({'owner' => 'root', 'group' => 'root'})}
      it {is_expected.to contain_file("/etc/kafka/mirrormaker/#{title}").with({'owner' => 'mirrormaker', 'group' => 'root'})}

      command_line = '/usr/bin/kafka-mirror-maker ' +
          '--abort.on.send.failure true ' +
          '--new.consumer ' +
          '--num.streams 1 ' +
          '--offset.commit.interval.ms 60000 ' +
          '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
          '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
          "--whitelist '^productname-v1-(?!.*-unknown).*|^logs-pro|^bons-.*-test|^productname-v2-(realtime|longterm|logs|ets|metrics|mts)-.*-.*'"

      service_name = "mirrormaker-#{title}"
      system_d_settings = {
          "#{service_name}/Service/Type" => 'simple',
          "#{service_name}/Unit/Wants" => 'basic.target',
          "#{service_name}/Unit/After" => 'basic.target network-online.target',
          "#{service_name}/Service/User" => 'mirrormaker',
          "#{service_name}/Service/TimeoutStopSec" => '300',
          "#{service_name}/Service/ExecStart" => command_line,
          "#{service_name}/Service/LimitNOFILE" => '32000',
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