define tbsystemd::autorestart (
  $restart = 'always',

) {
  tbsystemd::servicefile { "${name} autorestart":
    servicename => $name,
    filename    => 'restart',
    content     => {
      'Service' => {
        'Restart'    => $restart,
        'RestartSec' => '5',
      }
    },
  }
}