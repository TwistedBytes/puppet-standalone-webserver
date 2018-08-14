class tbsite::certs (
  $cleancerts = true,
) {
  if hiera("tbsite::certs::certs", undef) {
    $certs = hiera_array("tbsite::certs::certs")

    $all_certs = hiera_hash("certificates::all")

    $certs.each |String $cert| {
      if $all_certs[$cert] {
        ::tbsite::certs::certificate { $cert:
          * => $all_certs[$cert]
        }

      } else {
        notify{ "missing certiciate: ${cert}": }
      }
    }

  }

  file { "/etc/certs":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '755',
  }

  if $cleancerts {
    File <| title == "/etc/certs" |> {
      recurse => true,
      purge   => true,
      backup  => false,
      force   => true,
    }
  }

}
