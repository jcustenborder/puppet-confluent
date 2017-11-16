class confluent {
  Package<| tag == 'confluent' |> ->
  User<| tag == 'confluent' |> ->
  File<| tag == 'confluent' |> ->
  Service<| tag == 'confluent' |>
}
