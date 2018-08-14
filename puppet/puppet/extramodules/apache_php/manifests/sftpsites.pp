class apache_php::sftpsites (
  $sftpsites = {}
){

  validate_hash($sftpsites)

  create_resources('apache_php::sftpsite', $sftpsites)

}
