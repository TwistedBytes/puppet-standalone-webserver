class tbapache (

){

  $macros = hiera_hash('tbapache::macros', undef)

  if ($macros != undef) {
    validate_hash($macros)

    require ::tbapache::mod::macro

    create_resources('tbapache::tools::write_macro', $macros)
  }


}