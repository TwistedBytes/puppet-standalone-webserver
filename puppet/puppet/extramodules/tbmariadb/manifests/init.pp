class tbmariadb (
  $userandgrants = { },
  $grants = { },
){
  if ($userandgrants != undef) {
    validate_hash($userandgrants)

    create_resources('tbmariadb::userandgrant', $userandgrants)
  }

  if ($grants != undef) {
    validate_hash($grants)

    create_resources('tbmariadb::grant', $grants)
  }

}