require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
end
# TODO: Update code coverage to 95 pct !
at_exit { RSpec::Puppet::Coverage.report!(10)}

module Template
  class Helper
    EMTPY = true
  end
end