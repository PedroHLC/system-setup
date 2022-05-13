pkgs: pkgs.writeText "login-program.sh" ''
  _TTY="$(tty)"
  if [[ "$_TTY" == '/dev/tty1' ]]; then
    ${pkgs.shadow}/bin/login -f pedrohlc;
  elif [[ "$_TTY" == '/dev/tty2' ]]; then
    ${pkgs.shadow}/bin/login -f melinapn;
  else
    ${pkgs.shadow}/bin/login;
  fi
''
