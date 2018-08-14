# == Define: common::mkdir_p
# from: ghoneycutt/puppet-module-common
#
# Provide `mkdir -p` functionality for a directory
#
# Idea is to use this mkdir_p in conjunction with a file resource
#
# Example usage:
#
#  tbsite::mkdir::mkdir_p { '/some/dir/structure': }
#
#  file { '/some/dir/structure':
#    ensure  => directory,
#    require => tbsite::Mkdir::Mkdir_p['/some/dir/structure'],
#  }
#
define tbsite::mkdir::mkdir_p () {

  validate_absolute_path($name)

  if ! defined(Exec["mkdir_p-${name}"]) {
    exec { "mkdir_p-${name}":
      command => "mkdir -p ${name}",
      unless  => "test -d ${name}",
      path    => '/bin:/usr/bin',
    }
  }
}
