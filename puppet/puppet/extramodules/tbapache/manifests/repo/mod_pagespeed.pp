class tbapache::repo::mod_pagespeed (
) {

  yum::managed_yumrepo { 'mod-pagespeed':
    descr    => 'mod-pagespeed',
    baseurl  => 'http://dl.google.com/linux/mod-pagespeed/rpm/stable/x86_64',
    enabled  => 1,
    gpgcheck => 0,
  }
}
