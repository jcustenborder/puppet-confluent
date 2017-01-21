require 'spec_helper'

describe 'confluent::java_property' do
  let(:title) { 'broker.id' }
  let(:params) {
    {
        :value => '0',
        :path => '/etc/kafka/server.properties',
        :application => 'kafka'
    }
  }

  it { is_expected.to contain_ini_setting('kafka_broker.id') }
end