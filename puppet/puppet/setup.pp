
lookup('classes', Array[String], 'unique').include

sudo::conf { 'centos-user':
  priority => 10,
  content  => "# User rules for centos\ncentos ALL=(ALL) NOPASSWD:ALL",
}