class apache_php::sites (
  $sites    = undef,
) {

  $defaults = hiera_hash('apache_php::sites::defaults', {})
  $proftpd_active = hiera('apache_php::proftpd', true)

  if $proftpd_active {
    class { 'tbproftpd': }
  }

  $vhostdirs = ["/var/www", "/var/www/vhosts"]

  file { $vhostdirs:
    ensure => 'directory',
    mode   => '0711',
  }

  if ($sites != undef) {
    validate_hash($sites)

    # eerst packages instaleren
    # dat ivm uid uit de packages die in de weg kunnen zitten
    # van nieuwe users
    Package<| |> -> Apache_php::User<| |>

    create_resources('apache_php::site', $sites, $defaults)
  }
}
