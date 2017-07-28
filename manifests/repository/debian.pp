class confluent::repository::debian (
  $key_url        = $::confluent::params::key_url,
  $repository_url = $::confluent::params::repository_url
) inherits confluent::params {
  include ::apt

  apt::key { '41468433':
    source => $key_url,
    tag    => 'confluent'
  } ->
  apt::source { 'confluent':
    comment  => 'Confluent repo',
    location => $repository_url,
    release  => 'stable',
    repos    => 'main',
    include  => {
      'src' => false,
      'deb' => true,
    },
    tag      => 'confluent'
  }

  Apt::Key<| tag == 'confluent' |> -> Apt::Source<| tag == 'confluent' |> -> Package<| tag == 'confluent' |>
}