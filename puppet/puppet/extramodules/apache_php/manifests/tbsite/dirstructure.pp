define apache_php::tbsite::dirstructure (
  $basedir   = undef,
  $vhostname = undef,
  $uid       = undef,
  $gid       = undef,
) {

  file { ["${basedir}/${vhostname}/site", "${basedir}/${vhostname}/logs"]:
    ensure => 'directory',
    owner  => $uid,
    mode   => '0751',
    group  => $gid,
  }

  file { ["${basedir}/${vhostname}/private", "${basedir}/${vhostname}/private/bin"]:
    ensure => 'directory',
    owner  => $uid,
    mode   => '0750',
    group  => $gid,
  }

}