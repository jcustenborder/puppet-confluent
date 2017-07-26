module Helpers
  def help
    :available
  end

  def foo
    puts "Does this do anything"
  end

  def supported_osfamalies
    return {
        'RedHat' => [7],
        'Debian' => [8]
    }
  end
end