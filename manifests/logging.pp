define confluent::logging (
  Stdlib::Unixpath $path,
  Enum['absent', 'present'] $ensure = present,
  Hash $config                      = {}
) {
  $default_config = {
    'log4j.rootLogger'                               => 'INFO, stdout, roller',
    'log4j.appender.stdout'                          => 'org.apache.log4j.ConsoleAppender',
    'log4j.appender.stdout.layout'                   => 'org.apache.log4j.PatternLayout',
    'log4j.appender.stdout.layout.ConversionPattern' => '[%d] %p %m (%c)%n',
    'log4j.appender.roller'                          => 'org.apache.log4j.RollingFileAppender',
    'log4j.appender.roller.MaxFileSize'              => '100MB',
    'log4j.appender.roller.MaxBackupIndex'           => '10',
    'log4j.appender.roller.File'                     => '${kafka.logs.dir}/server.log',
    'log4j.appender.roller.layout'                   => 'org.apache.log4j.PatternLayout',
    'log4j.appender.roller.layout.ConversionPattern' => '[%d] %p %m (%c)%n',
    'log4j.logger.org.reflections'                   => 'ERROR'
  }
  $merged_config = merge($default_config, $config)

  confluent::properties { "${title}-logging":
    ensure => present,
    path   => $path,
    config => $merged_config
  }
}
