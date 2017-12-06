require 'spec_helper'

describe 'confluent::kafka::mirrormaker::instance' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      title = 'testing'
      let(:facts) {default_facts}
      let(:title) {title}

      default_params = {
          :consumer_config => {
              'group.id' => 'mirrormaker',
              'bootstrap.servers' => 'kafka-01:9092'
          },
          :producer_config => {
              'bootstrap.servers' => 'kafka-01:9092'
          },
          :whitelist => 'topic1|foo|.*bar'
      }

      service_name = "mirrormaker-#{title}"

      case osfamily
        when 'Debian'
          environment_file = "/etc/default/mirrormaker-#{title}"
        when 'RedHat'
          environment_file = "/etc/sysconfig/mirrormaker-#{title}"
      end

      unit_file = "/usr/lib/systemd/system/#{service_name}.service"
      producer_config='/etc/kafka/mirrormaker/testing/consumer.properties'
      consumer_config='/etc/kafka/mirrormaker/testing/producer.properties'
      logging_config_path='/etc/kafka/mirrormaker/testing/logging.properties'

      user = 'mirrormaker'

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
        it {is_expected.to contain_file("/etc/kafka/mirrormaker/#{title}").with({'owner' => user, 'group' => 'root'})}

        command_line = '/usr/bin/kafka-mirror-maker ' +
            '--abort.on.send.failure true ' +
            '--new.consumer ' +
            '--num.streams 1 ' +
            '--offset.commit.interval.ms 60000 ' +
            '--consumer.config /etc/kafka/mirrormaker/testing/consumer.properties ' +
            '--producer.config /etc/kafka/mirrormaker/testing/producer.properties ' +
            "--whitelist 'topic1|foo|.*bar'"

        it {is_expected.to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
        context 'with restart_on_logging_change => false' do
          let(:params) {super().merge({'restart_on_logging_change' => false})}
          it {is_expected.not_to contain_file(logging_config_path).that_notifies("Service[#{service_name}]")}
        end

        system_d_settings = {
            'Unit' => {
                'Wants' => 'basic.target',
                'After' => 'basic.target network-online.target',
            },
            'Service' => {
                'Type' => 'simple',
                'ExecStart' => command_line,
                'User' => user,
                'TimeoutStopSec' => 300,
                'LimitNOFILE' => 32000,
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
        end

        it {is_expected.to contain_file(unit_file).that_notifies('Exec[kafka-systemctl-daemon-reload]')}
        it {is_expected.to contain_service(service_name).with({'ensure' => 'running', 'enable' => true})}
        it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{unit_file}]")}
        it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{logging_config_path}]")}
        it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{producer_config}]")}
        it {is_expected.to contain_service(service_name).that_subscribes_to("File[#{consumer_config}]")}

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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
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

        it {is_expected.to contain_file(unit_file).with_content(/ExecStart=#{command_line}/)}
      end

    end
  end
end