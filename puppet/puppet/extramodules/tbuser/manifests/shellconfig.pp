define tbuser::shellconfig (
  $ensure   = 'present',
  $homedir,
  $owner,
  $group,
) {

  if ($ensure == 'present') {
    file { "${homedir}/.bash_history":
      ensure  => 'file',
      owner   => $owner,
      group   => $group,
      mode    => '0600',
      require => File["${homedir}"],
    }

    file { "${homedir}/.bash_profile":
      ensure  => 'file',
      owner   => $owner,
      group   => $group,
      mode    => '0600',
      source  => "puppet:///modules/${module_name}/shell/bash_profile",
      require => File["${homedir}"],
    }

    file { "${homedir}/.bashrc":
      ensure  => 'file',
      owner   => $owner,
      group   => $group,
      mode    => '0600',
      source  => "puppet:///modules/${module_name}/shell/bashrc",
      require => File["${homedir}"],
    }
    file { "${homedir}/.bashrc_local":
      ensure  => 'file',
      owner   => $owner,
      group   => $group,
      mode    => '0600',
      require => File["${homedir}"],
      replace => false,
    }
  } else {
    $jaildirs = prefix(['.bash_history', '.bash_profile', '.bashrc'], "${homedir}/")

    file { $jaildirs:
      ensure => 'absent',
      purge  => true,
      force  => true,
      backup => false,
    }
  }

}