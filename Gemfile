source 'https://rubygems.org'

group :development, :test do
  gem 'json', :require => false
  gem 'metadata-json-lint', :require => false
  gem 'puppetlabs_spec_helper', :require => false
  gem 'puppet-lint', :require => false
  gem 'rake', :require => false
  gem 'rspec-puppet', :require => false
  if RUBY_VERSION > '2'
    gem 'rubocop', :require => false
  end
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby