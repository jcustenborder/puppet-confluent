require 'spec_helper'

hash1 = { 'key1' => 'value'}
hash2 = { 'key2' => 'value'}
hash3 = { 'key1' => 'value2'}

describe 'merge_hash_with_key_rename' do
  it 'should exist' do
    expect(
        Puppet::Parser::Functions.function('merge_hash_with_key_rename')
    ).to eq('function_merge_hash_with_key_rename')
  end

  context 'with hash and prefix arguement' do
    it {is_expected.to run.with_params(hash1, hash2, 'some_prefix').and_return({'some_prefix/key1' => 'value', 'some_prefix/key2' => 'value'})}
    it {is_expected.to run.with_params(hash1, hash3, 'some_prefix').and_return({'some_prefix/key1' => 'value2'})}
  end

  context 'with bad or empty arguments' do
    it {is_expected.to run.with_params(['abc'], hash1, 123).and_raise_error(Puppet::ParseError)}
    it {is_expected.to run.with_params(hash1, hash2).and_raise_error(Puppet::ParseError)}
    it {is_expected.to run.and_raise_error(Puppet::ParseError)}
  end

end