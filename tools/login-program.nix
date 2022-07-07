{ writeText, shadow }:
# Auto-logins with pedrohlc in TTY1, and melinapn in TTY2
writeText "login-program.sh" ''
  _TTY="$(tty)"
  if [[ "$_TTY" == '/dev/tty1' ]]; then
    ${shadow}/bin/login -f pedrohlc;
  elif [[ "$_TTY" == '/dev/tty2' ]]; then
    ${shadow}/bin/login -f melinapn;
  else
    ${shadow}/bin/login;
  fi
''
