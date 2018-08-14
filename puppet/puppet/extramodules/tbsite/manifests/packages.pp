class tbsite::packages (
  $selinux = true,
) {
  $packagesToRemove = ['tuned', 'alsa']

  package { $packagesToRemove: ensure => absent, }

  case $::operatingsystem {
    'RedHat', 'CentOS', 'Fedora', 'Scientific', 'OracleLinux' : { include tbsite::packages::centos }
    'Debian', 'Ubuntu' : { include tbsite::packages::debian }
  }

  # ensure_packages (['rsync'])

  package { ['openssl']: ensure => 'latest', }

}
