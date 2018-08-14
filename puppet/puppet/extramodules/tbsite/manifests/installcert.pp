#openssl req -x509 -sha256 -newkey rsa:2048 \
#  -nodes \
#  -subj "/C=NL/ST=Overijsel/L=Enschede/O=Twisted Bytes B.V./OU=Operations/CN=*.twistedbytes.eu" \
#  -keyout star.twistedbytes.eu.key \
#  -out star.twistedbytes.eu.crt \
#  -days 1000

class tbsite::installcert (
  $certname = undef,
) {
  file { '/etc/certs':
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    ensure  => 'directory',
    recurse => true,
    purge   => true,
  }

  file { "/etc/certs/${certname}.key":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("site/certs/${certname}/${certname}.key.erb"),
  }

  file { "/etc/certs/${certname}.crt":
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => template("site/certs/${certname}/${certname}.crt.erb"),
  }

}
