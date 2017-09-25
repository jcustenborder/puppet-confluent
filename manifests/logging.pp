define confluent::logging (
  Stdlib::Unixpath $path,
  Enum['absent', 'present'] $ensure = present,
  Hash $config                      = {}
) {
  $default_config = {
    'log4j.rootLogger'                               => { 'value' => 'INFO, stdout, roller' },
    'log4j.appender.stdout'                          => { 'value' => 'org.apache.log4j.ConsoleAppender' },
    'log4j.appender.stdout.layout'                   => { 'value' => 'org.apache.log4j.PatternLayout' },
    'log4j.appender.stdout.layout.ConversionPattern' => { 'value' => '[%d] %p %m (%c)%n' },
    'log4j.appender.roller'                          => { 'value' => 'org.apache.log4j.DailyRollingFileAppender' },
    'log4j.appender.roller.DatePattern'              => { 'value' => "'.'yyyy-MM-dd-HH" },
    'log4j.appender.roller.File'                     => { 'value' => '${kafka.logs.dir}/server.log' },
    'log4j.appender.roller.layout'                   => { 'value' => 'org.apache.log4j.PatternLayout' },
    'log4j.appender.roller.layout.ConversionPattern' => { 'value' => '[%d] %p %m (%c)%n' },
  }
  $merged_config = merge($default_config, $config)
  $prefixed = prefix($merged_config, "${title}/")

  $java_property_defaults = {
    'ensure' => 'present',
    'path'   => $path,
  }
  ensure_resources(
    'confluent::java_property',
    $prefixed,
    $java_property_defaults
  )
}