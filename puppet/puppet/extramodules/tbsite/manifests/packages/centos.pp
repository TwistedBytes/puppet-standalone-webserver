class tbsite::packages::centos (
) {
  include yum::repo::epel

  Yumrepo <| |> -> Package <| |>

  $extrapackages = hiera_array('tbsite::packages::extra', [])

  $packagesToInstall = concat(['psmisc', 'ncdu', 'telnet',
    'unzip', 'sysstat', 'nano', 'htop', 'lsof',
    'wget', 'bzip2', 'mailx', 'vim', 'net-tools'],
    $extrapackages)

  $packagesToInstall.each |String $packageToInstall| {
    if ! defined(Package[$packageToInstall]) {
      package { [$packageToInstall]:
        ensure => 'installed',
        require => Class['Yum::Repo::Epel'],
      }
    }
  }

  file { 'selinux-config':
    path   => '/etc/selinux/config',
    ensure => 'file',
    before => Class['selinux'],
  }

  $selinux_mode = $::operatingsystemmajrelease ? {
    '6' => 'permissive',
    '7' => 'disabled'
  }

  class { selinux:
    mode => $selinux_mode
  }

  $servicesToStop = ['avahi-daemon']

  service { $servicesToStop:
    ensure => stopped,
    enable => false
  }

  package { ['openssh']: ensure => 'latest', }

}
