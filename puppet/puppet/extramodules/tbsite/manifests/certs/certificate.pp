define tbsite::certs::certificate (
  $ensure       = 'present',
  $destination  = '/etc/certs',
  $sourceBase   = 'puppet:///modules/site/certs',
  $domainname   = $name,
  $time         = undef,
  $key          = undef,
  $chain        = undef,
) {

  if ($ensure == 'present'){

    $sourceExtra  = "${domainname}/${time}"
    $certificateDir = "${destination}/${sourceExtra}"

    ::tbsite::mkdir::mkdir_p { $certificateDir: }

    file { ["${destination}/${domainname}", "${destination}/${domainname}/${time}"]:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'root',
      mode    => '755',
      require => ::tbsite::Mkdir::Mkdir_p[$certificateDir]
    }

    $files = concat([$key], values($chain))
    $sourceBase2 = "${sourceBase}/${sourceExtra}"

    ::tbsite::certs::certificate::writefile { $files:
      certificateDir => $certificateDir,
      sourceBase     => $sourceBase2,
    }

    $pemfile = "${certificateDir}/${domainname}.pem"

    concat { $pemfile:
      owner          => 'root',
      group          => 'root',
      mode           => '0600',
      ensure_newline => true,
    }

    $order = prefix(keys($chain), "${key}_")

    ::tbsite::certs::certificate::writepem { $order:
      sourceBase => $sourceBase2,
      pemfile    => $pemfile,
      hash       => $chain,
    }
  }
}

define tbsite::certs::certificate::writefile (
  $certificateDir = undef,
  $sourceBase     = undef,
  $owner          = 'root',
  $group          = 'root',
  $mode           = '0600') {
  file { "${certificateDir}/${title}":
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    source  => "${sourceBase}/${title}",
    require => tbsite::Mkdir::Mkdir_p[$certificateDir],
  }
}

define tbsite::certs::certificate::writepem (
  $sourceBase,
  $pemfile,
  $hash,) {

  $parts = split($title, '_')
  $order = $parts[1]

  concat::fragment { "${pemfile}_${order}":
    target => $pemfile,
    source => join([$sourceBase, $hash[$order]], '/'),
    order  => $order,
  }
}
