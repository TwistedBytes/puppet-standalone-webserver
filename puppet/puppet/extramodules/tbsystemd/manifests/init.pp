class tbsystemd (
  $services = { }
){

  create_resources('tbsystemd::service', $services)

}