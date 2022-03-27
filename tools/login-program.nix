pkgs: pkgs.writeText "login-program.sh" ''
  TTY="$(tty)"
  if [[ "$TTY" == '/dev/tty1' ]]; then
    ${pkgs.shadow}/bin/login -f pedrohlc;
  elif [[ "$TTY" == '/dev/tty2' ]]; then
    ${pkgs.shadow}/bin/login -f melinapn;
  else
    ${pkgs.shadow}/bin/login;
  fi
''
