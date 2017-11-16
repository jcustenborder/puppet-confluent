module Helpers
  def help
    :available
  end

  def foo
    puts "Does this do anything"
  end

  def supported_osfamalies
    return {
        'RedHat 7' => {
            'osfamily' => 'RedHat',
            'operatingsystem' => 'CentOS',
            'operatingsystemrelease' => '7.0',
            'operatingsystemmajrelease' => '7',
            'kernel' => 'Linux',
            'id' => 'root',
            'path' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
            'selinux' => true,
        },
        'Debian 8' => {
            'os' => {
                'name' => 'Debian',
                'release' => {
                    'full' => '8.0',
                    'major' => '8'
                }
            },
            'osfamily' => 'Debian',
            'operatingsystem' => 'Debian',
            'operatingsystemrelease' => '8.0',
            'kernel' => 'Linux',
            'id' => 'root',
            'path' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
            'selinux' => true,
        },
    }
  end



end