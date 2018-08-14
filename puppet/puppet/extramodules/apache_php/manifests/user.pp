# apache_php customer
# userpassword / $user_hash
# python -c 'import crypt; import random;import string; \
#  password="".join(random.SystemRandom().choice(string.ascii_letters + string.digits) for _ in range(14))  ; \
#  salt="".join(random.SystemRandom().choice(string.ascii_letters + string.digits) for _ in range(10)) ; \
#  print password ;print crypt.crypt(password, "$6$"+salt) '


define apache_php::user (
  $ensure              = 'present',
  $homedir             = undef,
  $username            = undef,
  $uid                 = undef,
  $gid                 = undef,
  $shell               = undef,
  $user_hash           = undef,
  $user_ssh_keys       = undef,
  $user_ssh_keys_extra = [],
  $create_ssh_key      = false,
  $convert_proftpd     = true,
  $create_home         = true,
  $split_authorized    = false,
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

  $real_shell = $shell ? {
    undef   => '/sbin/nologin',
    default => $shell,
  }

    $real_user_hash = $user_hash ? {
      # undef   => tbpassword_getpassline("${::fqdn}-system", $username),
      undef   => '!!',
      'keep'  => undef,
      default => $user_hash,
    }

  $user_comment_hiera = hiera('apache_php::user::comment', "${username} on ${::fqdn}")
  $user_comment = $user_comment_hiera ? {
    'variable-username' => $username,
    default             => $user_comment_hiera,
  }

  user { $username:
    ensure         => $ensure,
    comment        => $user_comment,
    home           => $homedir,
    shell          => $real_shell,
    uid            => $my_uid, # Let op bij installeren software, uid's worden gekozen door hoogste vrije te pakken
    gid            => $my_gid,
    expiry         => absent,
    managehome     => false,
    password       => $real_user_hash,
    purge_ssh_keys => true,
    require        => Group[$my_gid],
  }

  if ($ensure == 'present') {
    if $create_home {
      file { "${homedir}":
        ensure => 'directory',
        owner  => $username,
        group  => $my_gid,
      }
    }

    file { "${homedir}/.ssh":
      ensure  => 'directory',
      recurse => true,
      owner   => $username,
      group   => $my_gid,
      require => User[$username],
    }

    if $split_authorized {
      tbssh::split_authorized_keys { "${username}":
        user    => $username,
        group   => $my_gid,
        homedir => $homedir,
      }
    }

    $proftpd_active = hiera('apache_php::proftpd', true)

    if ($user_ssh_keys != undef) {
      $real_user_ssh_keys = unique(delete_undef_values(concat($user_ssh_keys, $user_ssh_keys_extra)))

      $fin_keys = sshkeys_convert_to_hash($real_user_ssh_keys, $username, $::fqdn)

      if ($convert_proftpd and $proftpd_active) {
        $before = Tbproftpd::Convert_pubkey[$username]
      } else {
        $before = undef
      }

      create_resources('apache_php::user::sshkey', $fin_keys, {
        file             => "$homedir/.ssh",
        ensure           => $ensure,
        home             => $homedir,
        before           => $before,
        convert_proftpd  => $convert_proftpd,
        split_authorized => $split_authorized,
      }
      )
    }

    if $proftpd_active {
      if ($convert_proftpd) {
        $authfile = "${homedir}/.ssh/authorized_keys"
        $sftpfile = "${homedir}/.ssh/sftp_authorized_keys"

        tbproftpd::convert_pubkey { $username:
          sftpfile => $sftpfile,
          authfile => $authfile,
          before   => File[$sftpfile],
        }
        file { $sftpfile:
          ensure => file,
          owner  => $username,
          mode   => '0600',
        }

      }
    }

  } else {
    file { "${homedir}":
      ensure  => $ensure,
      purge   => true,
      force   => true,
      recurse => true,
      backup  => false,
    }
  }

}
