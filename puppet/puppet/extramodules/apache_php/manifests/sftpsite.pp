define apache_php::sftpsite (
  $user = undef,
  $sitedir = undef,
){

  ssh::sftpchroot {$user:
    chroot_dir  => "$sitedir",
    match       => 'user',
    manage_user => true,
    gid         => 'apache',
  }
}
