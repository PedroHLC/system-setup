{ fetchFromGitHub }:

fetchFromGitHub {
  owner = "FilaCo";
  repo = "plymouth-theme-pedro-raccoon";
  rev = "f7fde1da0dde1ce861dff5617c79de6afbde29cb";
  hash = "sha256-AT5fiF0hDeb7xqk1Ni04kqE6R88ENQ2k7rlHW3cr+PU=";
  sparseCheckout = [ "pedro-raccoon" ];
  postFetch = ''
    mkdir -p $out/share/plymouth/themes
    mv $out/pedro-raccoon $out/share/plymouth/themes/
    substituteInPlace $out/share/plymouth/themes/pedro-raccoon/pedro-raccoon.plymouth \
      --replace-fail /usr/share/ /etc/
  '';
}
