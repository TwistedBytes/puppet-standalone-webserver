class tbsite::bash (
) {
  $aliases = hiera_hash('tbsite::bash::aliases')

  file { "/etc/profile.d/twistedbytes-aliasses.sh":
    owner   => 'root',
    group   => 'root',
    content => template('site/bash/aliases.sh.erb')
  }

  file { "/etc/profile.d/twistedbytes-div.sh":
    owner   => 'root',
    group   => 'root',
    content => template('site/bash/twistedbytes-div.sh.erb')
  }

  if ($::osfamily == 'RedHat' or $::osfamily == 'Debian') {
    file { "/etc/inputrc":
      owner   => 'root',
      group   => 'root',
      content => template('site/bash/inputrc.erb')
    }
  }

}
