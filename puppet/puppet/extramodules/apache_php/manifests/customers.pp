class apache_php::customers (
){
  $customers = hiera_hash("apache_php::customers::customers")

  validate_hash($customers)

  create_resources('@apache_php::user', $customers)
}
