class tbapache::mod::proxy_wstunnel {
  Class['::apache::mod::proxy'] -> Class['::tbapache::mod::proxy_wstunnel']
  ::apache::mod { 'proxy_wstunnel': }
}
