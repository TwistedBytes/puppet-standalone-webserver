class tbuser (
  $userpasswords = {},
  $users = undef,
){
  if ($userpasswords != undef) {
    validate_hash($userpasswords)

    create_resources('tbuser::setpassword', $userpasswords)
  }

  if ($users != undef) {
    validate_hash($users)

    create_resources('tbuser::user', $users)
  }
}