define tbapache::tools::write_macro (
  $content
) {

  file { "/etc/httpd/conf.d/macro_${name}.conf":
    ensure  => 'present',
    content => $content,
  }

}