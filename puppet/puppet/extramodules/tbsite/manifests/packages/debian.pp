class tbsite::packages::debian (
) {

  include ::apt
  Stage['first'] -> Class['Apt::Update']

  $extrapackages = hiera_array('tbsite::packages::extra', [])

  $packagesToInstall = concat(['psmisc', 'ncdu', 'bzip2', 'telnet', 'wget', 'htop', 'lsof', 'apt-transport-https',
    'bsd-mailx'], $extrapackages)

  ensure_packages($packagesToInstall)

  Package <| title == 'openssh-client' |> {
    ensure => 'latest',
  }

  Package <| title == 'openssh-server' |> {
    ensure => 'latest',
  }

}
