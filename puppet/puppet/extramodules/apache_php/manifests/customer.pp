define apache_php::customer (
  $ensure        = 'present',
  $homedir       = undef,
  $username      = undef,
  $uid           = undef,
  $gid           = undef,
  $shell         = undef,
  $user_hash     = undef,
  $user_ssh_keys = undef,
  $create_ssh_key = false,
  $convert_proftpd= true,
) {
  apache_php::user { $name:
    ensure         => $ensure,
    homedir        => $homedir,
    username       => $username,
    uid            => $uid,
    gid            => $gid,
    shell          => $shell,
    user_hash      => $user_hash,
    user_ssh_keys  => $user_ssh_keys,
    create_ssh_key => $create_ssh_key,
    convert_proftpd=> $convert_proftpd,
  }

}
