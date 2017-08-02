require 'spec_helper'

describe 'confluent::java_property' do
  let(:title) { 'kafka/broker.id' }
  let(:params) {
    {
        :value => '0',
        :path => '/etc/kafka/server.properties',
    }
  }

  it { is_expected.to contain_ini_setting('kafka/broker.id') }
end