{ lib, stdenv, fetchzip, ... }:
let
  fileId = "1460751560";
  fileName = "135799-winamp_classic.wsz";
in
stdenv.mkDerivation {
  version = "1.1";
  pname = "audacious-skin-winamp-classic";

  src = fetchzip {
    #url = "https://dl.opendesktop.org/api/files/download/id/${fileId}/${fileName}";
    url = "mirror://sourceforge/anitaos/Anitaos/Multimedia/Audacious%20classic%20skins/135799-winamp_classic.wsz";
    sha256 = "cAXw2J56Bx1sexj1rSxbTGUxN92lPXRi3OKouwFOqeM=";
    extension = "zip";
    stripRoot = false;
  };

  dontBuild = true;
  sourceRoot = ".";

  installPhase = ''
    install -dm 755 "$out"
    cp -dr --no-preserve='ownership' source/* "$out/"
  '';

  meta = {
    description = "Winamp Classic skin for Audacious";
    homepage = "https://www.gnome-look.org/p/1008329/";
    license = lib.licenses.publicDomain;
    platforms = lib.platforms.all;
  };
}
