class tbapache::mod::lbmethod_all {

  ::apache::mod { 'lbmethod_bybusyness': }
  ::apache::mod { 'lbmethod_byrequests': }
  ::apache::mod { 'lbmethod_bytraffic': }
  ::apache::mod { 'lbmethod_heartbeat': }
}
