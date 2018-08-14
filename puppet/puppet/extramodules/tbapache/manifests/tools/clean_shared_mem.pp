class tbapache::tools::clean_shared_mem (
) {

  file { "/usr/local/sbin/apache_clean_shared_mem.sh":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => "puppet:///modules/${module_name}/apache_clean_shared_mem.sh",
  }

}
