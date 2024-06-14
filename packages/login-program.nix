{ lib
, writeText
, coreutils
, shadow
, loginsPerTTY ? { "/dev/tty1" = "pedrohlc"; }
}:
# Handle auto-logins in the most lightweight way.
# Make sure to set loginProgram to "bash"!
let
  whens = lib.attrsets.mapAttrsToList
    (devfs: user: ''
      ${devfs})
        ${shadow}/bin/login -f ${user}
        ;;
    '')
    loginsPerTTY;
in
writeText "login-program.sh" ''
  case "$(${coreutils}/bin/tty)" in
    ${builtins.concatStringsSep "\n" whens}
    *)
      ${shadow}/bin/login
      ;;
  esac
''
