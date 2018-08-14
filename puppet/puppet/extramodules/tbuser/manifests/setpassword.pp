# This changes a password of a system user using the tbpassword module setpassword
# enable this temporary and it will change the password.
define tbuser::setpassword (
  $password,
  $context = $::fqdn,
) {
  $username = $name

  $real_context = "${context}_system"

  $reset = tbpassword_setpassword($real_context, $username, $password)

  User <| title == $username |> {
    password => tbpassword_getpassline($real_context, $username)
  }
}