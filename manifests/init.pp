class confluent {
  Package<| tag == 'confluent' |> ->
  User<| tag == 'confluent' |> ->
  File<| tag == 'confluent' |> ->
  Ini_setting <| tag == 'confluent' |> ->
  Ini_subsetting <| tag == 'confluent' |> ->
  Service<| tag == 'confluent' |>
}