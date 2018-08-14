define tbuser::user (
  $username            = $name,
  $ensure              = 'present',
  $homedir             = undef,
  $uid                 = undef,
  $gid                 = undef,
  $shell               = undef,
  $user_hash           = undef,
  $user_ssh_keys       = undef,
  $user_ssh_keys_extra = [],
  $create_ssh_key      = false,
  $convert_proftpd     = false,
  $create_home         = true,
  $purge_ssh_keys      = true,
  $groups              = undef,
  $setup_shell         = false,
  $manage_dotssh       = true,
  $userrequireclasses  = [],
) {
  $my_gid = $gid ? {
    undef   => $username,
    default => $gid,
  }
  $my_uid = $uid ? {
    undef   => undef,
    default => $uid,
  }

  if !defined(Group[$my_gid]) {
    group { $my_gid: ensure => present, }
  }

  $real_homedir = $homedir ? {
    undef   => "/home/${username}",
    default => $homedir,
  }

  $real_shell = $shell ? {
    undef   => '/sbin/nologin',
    default => $shell,
  }

  if $user_hash != 'keep' {
    $real_user_hash = $user_hash ? {
      undef   => tbpassword_getpassline("${::fqdn}-system", $username),
      default => $user_hash,
    }
  }

  $user_comment_hiera = hiera('apache_php::user::comment', 'Managed by puppet')
  $user_comment = $user_comment_hiera ? {
    'variable-username' => $username,
    default             => $user_comment_hiera,
  }

  user { $username:
    ensure         => $ensure,
    comment        => $user_comment,
    home           => $real_homedir,
    shell          => $real_shell,
    uid            => $my_uid, # Let op bij installeren software, uid's worden gekozen door hoogste vrije te pakken
    gid            => $my_gid,
    expiry         => absent,
    managehome     => false,
    password       => $real_user_hash,
    purge_ssh_keys => $purge_ssh_keys,
    require        => [Group[$my_gid], Class[$userrequireclasses]],
    groups         => $groups,
  }

  if $setup_shell == true {
    tbuser::shellconfig { $username:
      ensure  => $ensure,
      homedir => $real_homedir,
      owner   => $username,
      group   => $my_gid,
    }
  }

  if ($ensure == 'present') {
    if $create_home {
      file { "${real_homedir}":
        ensure => 'directory',
        owner  => $username,
        group  => $my_gid,
      }
    }

    if $manage_dotssh {
      file { "${real_homedir}/.ssh":
        ensure  => 'directory',
        recurse => true,
        owner   => $username,
        group   => $my_gid,
        require => User[$username],
      }
    }

    $proftpd_active = hiera('apache_php::proftpd', true)

    if ($user_ssh_keys != undef) {
      $real_user_ssh_keys = unique(delete_undef_values(concat($user_ssh_keys, $user_ssh_keys_extra)))

      $fin_keys = sshkeys_convert_to_hash($real_user_ssh_keys, $username, $::fqdn)

      if ($convert_proftpd) {
        if $proftpd_active {
          $before = Tbproftpd::Convert_pubkey[$username]
        }
      } else {
        $before = undef
      }

      create_resources('apache_php::user::sshkey', $fin_keys, {
        file            => "$real_homedir/.ssh",
        ensure          => $ensure,
        before          => $before,
        convert_proftpd => $convert_proftpd
      }
      )
    }

    if $proftpd_active {
      if ($convert_proftpd) {
        $sftpfile = "${real_homedir}/.ssh/sftp_authorized_keys"
        $authfile = "${real_homedir}/.ssh/authorized_keys"

        tbproftpd::convert_pubkey { $username:
          sftpfile => $sftpfile,
          authfile => $authfile,
          before   => File[$sftpfile],
        }
        file { $sftpfile:
          ensure => file,
          owner  => $user,
          mode   => '0600',
        }

      }
    }

  } else {
    file { "${real_homedir}":
      ensure  => $ensure,
      purge   => true,
      force   => true,
      recurse => true,
    }
  }

}
