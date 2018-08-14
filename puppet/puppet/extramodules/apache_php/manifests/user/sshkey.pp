define apache_php::user::sshkey (
  $ensure   = 'present',
  $key_name = undef,
  $user     = undef,
  $file     = undef,
  $home     = undef,
  $convert_proftpd = true,
  $split_authorized = false,
) {
  $keys_hash = hiera_hash('sshkeys::keys', undef)

  $fin_key = $keys_hash[$key_name]['key']
  $fin_type = $keys_hash[$key_name]['type']
  if $keys_hash[$key_name]['options'] {
    $fin_options = $keys_hash[$key_name]['options']
  } else {
    $fin_options = undef
  }

  $proftpd_active = hiera('apache_php::proftpd', true)

  if ($convert_proftpd and $proftpd_active) {
    $notify = Tbproftpd::Convert_pubkey[$user]
  } else {
    $notify = undef
  }

  if $split_authorized {
    ssh_authorized_key { "${key_name}_at_${user}_puppet":
      ensure  => $ensure,
      user    => $user,
      key     => $fin_key,
      type    => $fin_type,
      require => File[$file],
      target  => "${home}/.ssh/authorized_keys_puppet",
      before  => Concat::Fragment["${home}/.ssh/authorized_keys_puppet"],
    }
  } else {
    ssh_authorized_key { "${key_name}_at_${user}":
      ensure  => $ensure,
      user    => $user,
      key     => $fin_key,
      type    => $fin_type,
      options => $fin_options,
      require => File[$file],
      notify  => $notify,
    }

  }

}