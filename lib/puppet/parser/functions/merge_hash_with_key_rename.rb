module Puppet::Parser::Functions
  newfunction(:merge_hash_with_key_rename, :type => :rvalue, :doc => <<-EOS
    Merge hashA with HashB, while rename keys (prefix) with Prefix
    @param: argv[0]: Hash => { 'key' => 'value' }
    @param: argv[1]: Hash => { 'key1' => 'value' }
    @param: argv[2]: String => "prefix"
    @return: Hash  => { 'prefix/key' => 'value',
                        'prefix/key1 => 'value'}
  EOS
  ) do |args|

    raise(Puppet::ParseError, "merge_hash_with_key_rename(): Wrong number of arguments " +
        "given (#{args.size} for 3)") if args.size < 3

    raise(Puppet::ParseError, "merge_hash_with_key_rename(): Wrong type of arguments " +
        "given (#{args[0]}/#{args[1]} type of Hash)") if not args[0].is_a?(Hash) and not args[1].is_a?(Hash)

    raise(Puppet::ParseError, "merge_hash_with_key_rename(): Wrong type of arguments " +
        "given (#{args[2]} type of String)") if not args[2].is_a?(String)

    hash1 = args[0]
    hash2 = args[1]
    prefix = args[2]
    merged = hash1.merge(hash2)
    return merged.map { |key, value| { prefix + '/' + key => value}}.reduce Hash.new, :merge
  end
end