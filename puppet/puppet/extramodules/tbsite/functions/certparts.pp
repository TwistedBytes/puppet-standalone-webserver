function tbsite::certparts (
  String $certname,
) {

  $all_certs = hiera_hash("certificates::all")

  $_ssl_cert_hash = $all_certs[$certname]
  $_ssltime = $_ssl_cert_hash['time']

  if $_ssl_cert_hash['domainname'] {
    $ssl_domainname = $_ssl_cert_hash['domainname']
  } else {
    $ssl_domainname = $certname
  }

  $certparts = {
    'domainname' => $ssl_domainname,
    'time'       => $_ssltime,
    'key'        => "/etc/certs/${ssl_domainname}/${_ssltime}/${$_ssl_cert_hash['key']}",
    'cert'       => "/etc/certs/${ssl_domainname}/${_ssltime}/${ssl_domainname}.crt",
    'fullchain'  => "/etc/certs/${ssl_domainname}/${_ssltime}/${ssl_domainname}.pem",
  }
}