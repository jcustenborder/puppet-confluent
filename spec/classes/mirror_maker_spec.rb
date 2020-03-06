require 'spec_helper'

describe 'confluent::kafka::mirrormaker' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      default_params = {
          'bootstrap_servers' => %w(kafka-01:9092 kafka-02:9092 kafka-03:9092),
          'connect_cluster' => %w(kafka-connect-01:8083 kafka-connect-02:8083 kafka-connect-03:8083),
          'zookeeper_connect' => %w(zookeeper-01:2181 zookeeper-02:2181 zookeeper-03:2181),
          'config' => {
              'confluent.controlcenter.streams.consumer.request.timeout.ms' => {
                  'value' => '180000'
              },
          }
      }
    end
  end
end
