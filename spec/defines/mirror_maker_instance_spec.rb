require 'spec_helper'

describe 'confluent::kafka::mirrormaker::instance' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      title = 'testing'


      osfamily = default_facts['osfamily']
      let(:facts) {default_facts}
      let(:title) {title}

      default_params = {
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
          :whitelist => 'topic1|foo|.*bar'
      }

      service_name = "mirrormaker-#{title}"

      context 'with whitelist' do
        let(:params) {default_params}

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
            "--whitelist 'topic1|foo|.*bar'"


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

      context 'with blacklist' do
        params = default_params.clone
        params.delete(:whitelist)
        params[:blacklist] = 'topic1|foo|.*bar'
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--new.consumer ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            "--blacklist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

      context 'with abort_on_send_failure' do
        params = default_params.clone
        params[:abort_on_send_failure] = false
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure false ' +
            '--new.consumer ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

      context 'with old consumer' do
        params = default_params.clone
        params[:new_consumer] = false
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

      context 'with offset_commit_interval_ms' do
        params = default_params.clone
        params[:offset_commit_interval_ms] = 10000
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--new.consumer ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 10000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

      context 'with consumer_rebalance_listener' do
        params = default_params.clone
        params[:consumer_rebalance_listener] = 'com.example.RebalanceListener'
        params[:consumer_rebalance_listener_args] = 'This is a grouping of arguments'
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--new.consumer ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            '--consumer.rebalance.listener com.example.RebalanceListener ' +
            "--rebalance.listener.args 'This is a grouping of arguments' " +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

      context 'with message_handler' do
        params = default_params.clone
        params[:message_handler] = 'com.example.MessageHandler'
        params[:message_handler_args] = 'This is a grouping of arguments'
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--new.consumer ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            '--message.handler com.example.MessageHandler ' +
            "--message.handler.args 'This is a grouping of arguments' " +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

      context 'with num_streams' do
        params = default_params.clone
        params[:num_streams] = 10
        let(:params) {params}
        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--new.consumer ' +
            '--num.streams 10 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_ini_setting("#{service_name}/Service/ExecStart").with({'value' => command_line})}
      end

    end
  end
end