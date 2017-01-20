define confluent::java_setting ($ensure='present', $path='/etc/kafka/server.properties', $value=unset, $application) {
  $setting_name = "${application}_${name}"

  ini_subsetting{ $setting_name:
    ensure            => $ensure,
    path              => $path,
    section           => '',
    setting           => $name,
    subsetting        => '',
    key_val_separator => '=',
    quote_char        => '"',
    tag               => "${application}-setting",
    value             => $value
  }
}