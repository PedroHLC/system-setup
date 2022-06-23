{ lib
, fetchFromGitHub
, resholve
, bash
, bluez
, coreutils
, fzf
, gnugrep
, less
, procps
, util-linux
}:

resholve.mkDerivation rec {
  pname = "fzf-bluetooth";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "varbhat";
    repo = "fzf-bluetooth";
    rev = "v${version}";
    sha256 = "j0ssvc6vS6tvDg3BCdCPSWCPNP03IwzDhTI8Bo1nEQs=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm555 ${pname} $out/bin/${pname}
  '';

  solutions = {
    default = {
      scripts = [ "bin/${pname}" ];
      interpreter = "${bash}/bin/bash";
      inputs = [ bluez coreutils fzf gnugrep less procps util-linux ];
      keep = {
        "$fzf_command" = true;
      };
      execer = [
        "cannot:${procps}/bin/pgrep"
      ];
    };
  };

  meta = with lib; {
    description = "TUI for bluetoothctl.";
    homepage = "https://github.com/varbhat/fzf-bluetooth";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pedrohlc ];
    mainProgram = "${pname}";
  };
}
