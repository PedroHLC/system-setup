{ stdenv, lib, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation {
  pname = "ksysrqd-${kernel.version}";
  version = "unstable-20220129-3e5e740";

  src = fetchFromGitHub {
    owner = "ipcjk";
    repo = "ksysrqd";
    rev = "3e5e7409454750083218341e801184d721165116";
    hash = "sha256-wV8v4L+3vmSRDpDPLab46njIwRLHuDbad1ZvB6LDGMA=";
  };

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  postPatch = ''
    substituteInPlace ksysrqd.c \
      --replace '"b)' '"o)ff system\n" "b)' \
      --replace " || letter == 'b'" " || letter == 'b' || letter == 'o'"
  '';

  buildPhase = ''
    make "-C${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" M=$(pwd) modules
  '';

  installPhase = ''
    install -D ksysrqd.ko -t "$out/lib/modules/${kernel.modDirVersion}/kernel/extra/"
  '';

  meta = with lib; {
    description = "A Linux kernel module for calling magic sysrq-keys over TCP/IP. ";
    homepage = "https://github.com/ipcjk/ksysrqd";
    license = licenses.publicDomain;
    platforms = platforms.linux;
  };
}
