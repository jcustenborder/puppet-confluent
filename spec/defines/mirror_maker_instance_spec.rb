require 'spec_helper'

describe 'confluent::kafka::mirrormaker::instance' do
  supported_osfamalies.each do |operating_system, default_facts|
    context "on #{operating_system}" do
      osfamily = default_facts['osfamily']
      let(:facts) {default_facts}
      let(:title) {'testing'}
      let(:params) {
        {
            :client_id => 'instance-01',
            :consumer_config => {

            },
            :producer_config => {

            }
        }
      }

      it {is_expected.to contain_class('confluent::kafka::mirrormaker')}
      it {is_expected.to contain_file('/var/log/mirrormaker')}
      it {is_expected.to contain_file('/var/log/mirrormaker/testing')}

      it {is_expected.to contain_file('/etc/kafka/mirrormaker')}
      it {is_expected.to contain_file('/etc/kafka/mirrormaker/testing')}
    end
  end
end