require 'spec_helper'

describe 'confluent::kafka::broker' do

  context 'with no params' do
    it do
      is_expected.to contain_package('confluent-kafka-2.11')
      is_expected.to contain_ini_setting('kafka_log.dirs').with({
            'path'  => '/etc/kafka/server.properties',
            'value' => '/var/lib/kafka'
      })
      is_expected.to contain_user('kafka')
      is_expected.to contain_service('kafka')
    end
  end
end